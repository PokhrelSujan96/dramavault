import asyncio
import json
import shutil
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from starlette.concurrency import run_in_threadpool

from app.api.routes.management import repository
from app.core.security import Principal, require_admin
from app.domain.models import ProjectStatus, StoryProject
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter()


async def probe_duration(path: Path) -> int:
    executable = shutil.which("ffprobe")
    if not executable:
        raise HTTPException(503, "Video inspection is unavailable")
    process = await asyncio.create_subprocess_exec(
        executable,
        "-v",
        "error",
        "-show_entries",
        "format=duration,format_name:stream=codec_type",
        "-of",
        "json",
        str(path),
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    try:
        stdout, _ = await asyncio.wait_for(process.communicate(), timeout=30)
    except TimeoutError as error:
        process.kill()
        await process.communicate()
        raise HTTPException(422, "Video inspection timed out") from error
    try:
        details = json.loads(stdout)
        if "mp4" not in details["format"]["format_name"].split(","):
            raise ValueError("Not an MP4 container")
        duration = round(float(details["format"]["duration"]))
        if process.returncode or not any(
            stream["codec_type"] == "video" for stream in details["streams"]
        ):
            raise ValueError("No video stream")
        if not 1 <= duration <= 3600:
            raise ValueError("Invalid duration")
        return duration
    except (ValueError, KeyError, TypeError) as error:
        raise HTTPException(422, "Upload a valid video under one hour") from error


@router.post("/series/{series_id}/upload", status_code=201)
async def upload_episode(
    series_id: UUID,
    file: UploadFile = File(),
    title: str = Form(min_length=1, max_length=160),
    episode_number: int = Form(ge=1, le=100000),
    description: str = Form(default="", max_length=2000),
    thumbnail_url: str = Form(
        default="", max_length=2048, pattern=r"^(https://[^\s]+)?$"
    ),
    principal: Principal = Depends(require_admin),
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    await repo.get("series", str(series_id))
    existing = (
        await repo.client.table("episodes")
        .select("id,duration_seconds")
        .eq("series_id", str(series_id))
        .eq("episode_number", episode_number)
        .limit(1)
        .execute()
    )
    if existing.data:
        raise HTTPException(409, "Episode number is already in use")
    if file.content_type != "video/mp4":
        raise HTTPException(422, "Upload an MP4 video")
    project = StoryProject(
        owner_id=UUID(principal.user_id),
        title=title,
        premise=description,
        status=ProjectStatus.ready,
        progress=100,
    )
    key = f"projects/{project.id}/uploaded.mp4"
    revision = str(uuid4())
    with TemporaryDirectory(prefix="dramabyte-upload-") as directory:
        path = Path(directory) / "episode.mp4"
        size = 0
        with path.open("wb") as output:
            while chunk := await file.read(1024 * 1024):
                size += len(chunk)
                if size > 250 * 1024 * 1024:
                    raise HTTPException(413, "Episode must be under 250 MB")
                output.write(chunk)
        duration = await probe_duration(path)
        await run_in_threadpool(
            R2Storage().upload_revision, path, key, "video/mp4", revision
        )
    await repo.create("projects", project.model_dump(mode="json"))
    try:
        for provider in ["cloudflare-r2-preview", "dramabyte-published"]:
            await repo.create(
                "generation_jobs",
                {
                    "project_id": str(project.id),
                    "stage": "publish",
                    "provider": provider,
                    "status": "completed",
                    "output": {
                        "key": key,
                        "revision": revision,
                        "width": 1080,
                        "height": 1920,
                        "captions_burned": True,
                    },
                },
            )
        return await repo.create(
            "episodes",
            {
                "project_id": str(project.id),
                "series_id": str(series_id),
                "episode_number": episode_number,
                "title": title,
                "description": description,
                "thumbnail_url": thumbnail_url,
                "duration_seconds": duration,
            },
        )
    except Exception:
        await repo.delete("projects", str(project.id))
        raise
