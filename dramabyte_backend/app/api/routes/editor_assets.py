from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from starlette.concurrency import run_in_threadpool

from app.api.dependencies import project_repository
from app.core.security import require_admin
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.repositories.projects import ProjectRepository

router = APIRouter(dependencies=[Depends(require_admin)])
MAX_IMAGE_BYTES = 20 * 1024 * 1024
IMAGE_TYPES = {
    "image/png": ".png",
    "image/jpeg": ".jpg",
    "image/webp": ".webp",
}
IMAGE_SIGNATURES = {
    "image/png": b"\x89PNG\r\n\x1a\n",
    "image/jpeg": b"\xff\xd8\xff",
}


@router.post("/project/{project_id}/assets/image")
async def upload_editor_image(
    project_id: UUID,
    file: UploadFile = File(...),
    repository: ProjectRepository = Depends(project_repository),
) -> dict[str, Any]:
    await repository.get(project_id, None)
    content_type = (file.content_type or "").lower()
    extension = IMAGE_TYPES.get(content_type)
    if extension is None:
        raise HTTPException(415, "Upload a PNG, JPEG, or WebP image")
    data = await file.read(MAX_IMAGE_BYTES + 1)
    if not data or len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(413, "Image must be between 1 byte and 20 MB")
    if content_type == "image/webp":
        valid_signature = data[:4] == b"RIFF" and data[8:12] == b"WEBP"
    else:
        valid_signature = data.startswith(IMAGE_SIGNATURES[content_type])
    if not valid_signature:
        raise HTTPException(415, "The uploaded file does not match its image type")
    key = f"private/editor/{project_id}/{uuid4()}{extension}"
    with TemporaryDirectory(prefix="dramabyte-editor-asset-") as directory:
        path = Path(directory) / f"asset{extension}"
        path.write_bytes(data)
        storage = R2Storage()
        await run_in_threadpool(storage.upload, path, key, content_type)
        url = storage.public_url(key)
    return {"asset_key": key, "image_url": url, "content_type": content_type}
