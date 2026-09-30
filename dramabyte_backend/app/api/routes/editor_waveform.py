import hashlib
import json
import logging
from collections.abc import Mapping
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import cast
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from redis import Redis
from starlette.concurrency import run_in_threadpool

from app.api.dependencies import project_repository
from app.core.config import settings
from app.core.security import require_admin
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.audio_waveform import audio_peaks
from app.infrastructure.rendering import download
from app.infrastructure.repositories.projects import ProjectRepository

router = APIRouter(dependencies=[Depends(require_admin)])
logger = logging.getLogger(__name__)


def waveform_for(key: str) -> list[float]:
    cache_key = "editor-waveform:" + hashlib.sha256(key.encode()).hexdigest()
    cache: Redis | None = Redis.from_url(settings.redis_url)
    try:
        cached = cache.get(cache_key) if cache is not None else None
        if cached:
            return list(json.loads(cast(bytes, cached)))
    except Exception as error:
        logger.warning("waveform_cache_read_failed: %s", type(error).__name__)
        cache = None
    storage = R2Storage()
    metadata = storage.client.head_object(Bucket=storage.bucket, Key=key)
    if metadata["ContentLength"] > 500_000_000:
        raise ValueError("Video is too large for waveform preview")
    with TemporaryDirectory(prefix="dramabyte-waveform-") as folder:
        path = Path(folder) / "audio-source.mp4"
        download(storage.signed_url(key), path)
        peaks = audio_peaks(path)
    if cache is not None:
        try:
            cache.set(cache_key, json.dumps(peaks), ex=86400)
        except Exception as error:
            logger.warning("waveform_cache_write_failed: %s", type(error).__name__)
    return peaks


@router.get("/project/{project_id}/waveform")
async def waveform(
    project_id: UUID,
    repo: ProjectRepository = Depends(project_repository),
) -> dict[str, list[float]]:
    await repo.get(project_id, None)
    response = await (
        repo.client.table("generation_jobs")
        .select("output")
        .eq("project_id", str(project_id))
        .eq("provider", "cloudflare-r2-preview")
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )
    if not response.data or not isinstance(response.data[0], Mapping):
        raise HTTPException(404, "Audio preview is not ready")
    output = response.data[0].get("output")
    key = output.get("key") if isinstance(output, Mapping) else None
    if not isinstance(key, str) or not key:
        raise HTTPException(404, "Audio preview is not ready")
    try:
        return {"peaks": await run_in_threadpool(waveform_for, key)}
    except ValueError as error:
        raise HTTPException(422, str(error)) from error
