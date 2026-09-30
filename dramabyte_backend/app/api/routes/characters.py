from collections.abc import Mapping
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Annotated, Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from starlette.concurrency import run_in_threadpool

from app.api.routes.management import repository
from app.core.security import require_admin
from app.domain.hybrid import CharacterBody
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.reference_images import normalize_reference
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter(dependencies=[Depends(require_admin)])


@router.get("/series/{series_id}/characters")
async def characters(
    series_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    await repo.get("series", str(series_id))
    result = (
        await repo.client.table("series_characters")
        .select("*")
        .eq("series_id", str(series_id))
        .order("created_at")
        .execute()
    )
    storage = R2Storage()
    return {
        "items": [
            {
                **dict(row),
                "reference_url": storage.signed_url(str(row["reference_key"])),
            }
            for row in result.data
            if isinstance(row, Mapping)
        ]
    }


@router.post("/series/{series_id}/characters", status_code=201)
async def add_character(
    series_id: UUID,
    name: Annotated[str, Form(min_length=1, max_length=80)],
    description: Annotated[str, Form(min_length=20, max_length=2000)],
    portrait: Annotated[UploadFile, File()],
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    await repo.get("series", str(series_id))
    body = CharacterBody(name=name, description=description)
    if portrait.content_type not in {"image/png", "image/jpeg", "image/webp"}:
        raise HTTPException(422, "Upload a PNG, JPEG or WebP character portrait")
    with TemporaryDirectory(prefix="dramabyte-character-") as directory:
        source, normalized = Path(directory) / "input", Path(directory) / "portrait.png"
        size = 0
        with source.open("wb") as file:
            while chunk := await portrait.read(1024 * 1024):
                size += len(chunk)
                if size > 10 * 1024 * 1024:
                    raise HTTPException(413, "Character portrait must be under 10 MB")
                file.write(chunk)
        try:
            await run_in_threadpool(normalize_reference, source, normalized)
        except (RuntimeError, ValueError) as error:
            raise HTTPException(422, "Invalid character portrait") from error
        key = f"characters/{series_id}/{uuid4()}.png"
        storage = R2Storage()
        url = await run_in_threadpool(storage.upload, normalized, key, "image/png")
    result = await repo.create(
        "series_characters",
        {
            "series_id": str(series_id),
            **body.model_dump(),
            "reference_key": key,
        },
    )
    return {**result, "reference_url": url}
