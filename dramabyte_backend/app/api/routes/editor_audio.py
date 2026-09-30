from typing import Any, Literal, cast
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from starlette.concurrency import run_in_threadpool

from app.api.dependencies import project_repository
from app.core.security import require_admin
from app.infrastructure.production_guard import production_guard
from app.infrastructure.queue.editor_audio_tasks import replace_editor_audio
from app.infrastructure.repositories.projects import ProjectRepository

router = APIRouter(dependencies=[Depends(require_admin)])
PROVIDER = "dramabyte-editor-audio"


class VoiceReplacement(BaseModel):
    request_id: UUID
    reference_id: str = Field(pattern=r"^[a-fA-F0-9]{32}$")
    paid_confirmed: Literal[True]


def public_job(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": row["id"],
        "status": row["status"],
        "reference_id": row.get("input", {}).get("reference_id"),
        "error": row.get("error_message"),
    }


@router.get("/project/{project_id}/audio")
async def audio_status(
    project_id: UUID,
    repo: ProjectRepository = Depends(project_repository),
) -> dict[str, Any] | None:
    await repo.get(project_id, None)
    result = await (
        repo.client.table("generation_jobs")
        .select("*")
        .eq("project_id", str(project_id))
        .eq("provider", PROVIDER)
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )
    return (
        public_job(dict(cast(dict[str, Any], result.data[0]))) if result.data else None
    )


@router.post("/project/{project_id}/audio")
async def change_audio(
    project_id: UUID,
    body: VoiceReplacement,
    repo: ProjectRepository = Depends(project_repository),
) -> dict[str, Any]:
    async with production_guard(str(project_id)):
        project = await repo.get(project_id, None)
        existing = await (
            repo.client.table("generation_jobs")
            .select("*")
            .eq("id", str(body.request_id))
            .execute()
        )
        if existing.data:
            row = dict(cast(dict[str, Any], existing.data[0]))
            if (
                row["project_id"] != str(project_id)
                or row["provider"] != PROVIDER
                or row["input"]["reference_id"] != body.reference_id.lower()
            ):
                raise HTTPException(409, "Request ID belongs to another operation")
            return public_job(row)
        if project.status not in {"ready", "published"}:
            raise HTTPException(409, "Finish production before changing narration")
        if project.production_mode == "dialogue_pilot":
            raise HTTPException(
                409, "Voice replacement supports narrated episodes only"
            )
        latest = await audio_status(project_id, repo)
        if latest and latest["status"] in {"queued", "processing"}:
            raise HTTPException(409, "A voice replacement is already running")
        try:
            await repo.client.rpc("editor_audio_ready").execute()
        except Exception as error:
            raise HTTPException(
                503, "Apply migration 0013 before changing voices"
            ) from error
        inserted = (
            await repo.client.table("generation_jobs")
            .insert(
                {
                    "id": str(body.request_id),
                    "project_id": str(project_id),
                    "stage": "voice",
                    "provider": PROVIDER,
                    "status": "queued",
                    "input": {"reference_id": body.reference_id.lower()},
                }
            )
            .execute()
        )
        try:
            await run_in_threadpool(
                replace_editor_audio.apply_async,
                args=[str(body.request_id)],
                task_id=str(body.request_id),
                queue="default",
            )
        except Exception as error:
            raise HTTPException(
                503, "Dispatch uncertain. Check audio status; do not submit again."
            ) from error
        return public_job(dict(cast(dict[str, Any], inserted.data[0])))
