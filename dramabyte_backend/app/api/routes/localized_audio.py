from typing import Any, Literal, cast
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from starlette.concurrency import run_in_threadpool

from app.api.dependencies import project_repository
from app.core.security import require_admin
from app.infrastructure.production_guard import production_guard
from app.infrastructure.queue.hindi_audio_tasks import generate_hindi_audio
from app.infrastructure.repositories.projects import ProjectRepository

router = APIRouter(dependencies=[Depends(require_admin)])
PROVIDER = "dramabyte-localization-hi"
HINDI_VOICES = [
    {"id": "dcd006182803481390993aa6e9669207", "name": "Hindi storyteller · Male"},
    {"id": "83c19893c4974594839bd2d101b1fd66", "name": "Hindi storyteller · Female"},
]
HINDI_MODEL_ID = "s2.1-pro-free"


class HindiAudioRequest(BaseModel):
    request_id: UUID
    voice_id: str = Field(
        pattern=r"^(dcd006182803481390993aa6e9669207|83c19893c4974594839bd2d101b1fd66)$"
    )
    paid_confirmed: Literal[True]


def public_job(row: dict[str, Any]) -> dict[str, Any]:
    raw_output = row.get("output")
    output = cast(dict[str, Any], raw_output) if isinstance(raw_output, dict) else {}
    raw_input = row.get("input")
    input_data = cast(dict[str, Any], raw_input) if isinstance(raw_input, dict) else {}
    audio_key = output.get("audio_key")
    audio_url = None
    if audio_key:
        from app.infrastructure.adapters.r2 import R2Storage

        audio_url = R2Storage().signed_url(str(audio_key))
    return {
        "id": row["id"],
        "status": row["status"],
        "error": row.get("error_message"),
        "language": output.get("language", "hi"),
        "language_name": output.get("language_name", "हिन्दी"),
        "voice_id": output.get("voice_id") or input_data.get("voice_id"),
        "audio_url": audio_url,
        "captions": output.get("captions", []),
        "translated_script": output.get("translated_script", ""),
        "model_id": output.get("model_id", HINDI_MODEL_ID),
    }


@router.get("/voices")
async def hindi_voices() -> list[dict[str, str]]:
    return HINDI_VOICES


@router.get("/project/{project_id}/languages/hi")
async def hindi_status(
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


@router.post("/project/{project_id}/languages/hi")
async def create_hindi_audio(
    project_id: UUID,
    body: HindiAudioRequest,
    repo: ProjectRepository = Depends(project_repository),
) -> dict[str, Any]:
    async with production_guard(str(project_id)):
        project = await repo.get(project_id, None)
        if project.status not in {"ready", "published"}:
            raise HTTPException(409, "Finish production before translating audio")
        if project.production_mode == "dialogue_pilot":
            raise HTTPException(409, "Hindi audio is available for narrated episodes")
        if not project.language.lower().startswith("en"):
            raise HTTPException(
                409, "Hindi localization currently requires an English episode"
            )
        duplicate = await (
            repo.client.table("generation_jobs")
            .select("*")
            .eq("id", str(body.request_id))
            .execute()
        )
        if duplicate.data:
            row = dict(cast(dict[str, Any], duplicate.data[0]))
            if (
                row["project_id"] != str(project_id)
                or row["provider"] != PROVIDER
                or row.get("input", {}).get("voice_id") != body.voice_id
            ):
                raise HTTPException(409, "Request ID belongs to another operation")
            return public_job(row)
        latest = await (
            repo.client.table("generation_jobs")
            .select("*")
            .eq("project_id", str(project_id))
            .eq("provider", PROVIDER)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )
        job_id = str(body.request_id)
        if latest.data:
            row = dict(cast(dict[str, Any], latest.data[0]))
            latest_input = row.get("input")
            latest_voice = (
                latest_input.get("voice_id") if isinstance(latest_input, dict) else None
            )
            if row["status"] in {"queued", "processing"}:
                return public_job(row)
            if row["status"] == "completed" and latest_voice == body.voice_id:
                return public_job(row)
            previous_output = row.get("output")
            translated_script = (
                previous_output.get("translated_script", "")
                if isinstance(previous_output, dict)
                else ""
            )
            inserted_data = None
            if (
                row["status"] != "completed"
                and isinstance(previous_output, dict)
                and previous_output.get("raw_audio_key")
                and previous_output.get("model_id", HINDI_MODEL_ID) == HINDI_MODEL_ID
            ):
                raw_input = row.get("input")
                previous_input = raw_input if isinstance(raw_input, dict) else {}
                if previous_input.get("voice_id") != body.voice_id:
                    raise HTTPException(
                        409,
                        "Resume the saved Hindi audio with its original voice",
                    )
                job_id = str(row["id"])
                await (
                    repo.client.table("generation_jobs")
                    .update({"status": "queued", "error_message": None})
                    .eq("id", job_id)
                    .execute()
                )
                row["status"] = "queued"
                row["error_message"] = None
                inserted_data = row
        else:
            inserted_data = None
        if inserted_data is None:
            created = await (
                repo.client.table("generation_jobs")
                .insert(
                    {
                        "id": job_id,
                        "project_id": str(project_id),
                        "stage": "voice",
                        "provider": PROVIDER,
                        "status": "queued",
                        "input": {"voice_id": body.voice_id},
                        "output": (
                            {"translated_script": translated_script}
                            if latest.data and translated_script
                            else {}
                        ),
                    }
                )
                .execute()
            )
            inserted_data = dict(cast(dict[str, Any], created.data[0]))
        try:
            await run_in_threadpool(
                generate_hindi_audio.apply_async,
                args=[job_id],
                task_id=job_id,
                queue="default",
            )
        except Exception as error:
            raise HTTPException(
                503, "Dispatch uncertain. Check language status before retrying."
            ) from error
        return public_job(inserted_data)
