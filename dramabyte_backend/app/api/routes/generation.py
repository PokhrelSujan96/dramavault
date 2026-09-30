from collections.abc import Mapping
from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, Header, HTTPException

from app.api.dependencies import project_repository
from app.api.editor_schemas import EditorState
from app.api.schemas import (
    GenerateScriptBody,
    GenerationResultResponse,
    JobResponse,
    ScriptResponse,
    StartGenerationBody,
)
from app.application.services import GenerationService
from app.core.security import Principal, require_admin
from app.domain.models import GenerationRequest
from app.infrastructure.adapters.deepseek import DeepSeekScriptProvider
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.queue.tasks import export_production
from app.infrastructure.repositories.projects import ProjectRepository

router = APIRouter()


async def _latest(
    repository: ProjectRepository,
    project_id: UUID,
    provider: str,
) -> dict[str, Any]:
    query = (
        repository.client.table("generation_jobs")
        .select("output,error_message,status")
        .eq("project_id", str(project_id))
        .eq("provider", provider)
    )
    if provider == "dramabyte-published":
        query = query.eq("status", "completed")
    response = await query.order("created_at", desc=True).limit(1).execute()
    if not response.data or not isinstance(response.data[0], Mapping):
        return {}
    return dict(response.data[0])


def _output(row: dict[str, Any]) -> dict[str, Any]:
    value = row.get("output")
    return dict(value) if isinstance(value, Mapping) else {}


@router.get("/project/{project_id}", response_model=GenerationResultResponse)
async def result(
    project_id: UUID,
    principal: Principal = Depends(require_admin),
    repository: ProjectRepository = Depends(project_repository),
) -> GenerationResultResponse:
    project = await repository.get(project_id, None)
    preview_row = await _latest(repository, project_id, "cloudflare-r2-preview")
    published_row = await _latest(repository, project_id, "dramabyte-published")
    editor_row = await _latest(repository, project_id, "dramabyte-editor")
    hybrid_row = await _latest(repository, project_id, "dramabyte-hybrid")
    localization_row = await _latest(
        repository, project_id, "dramabyte-localization-hi"
    )
    preview_key = _output(preview_row).get("key")
    published_key = _output(published_row).get("key")
    storage = R2Storage()
    preview_url = storage.public_url(str(preview_key)) if preview_key else None
    published_output = _output(published_row)
    published_url = (
        storage.published_url(
            str(published_key), str(published_output.get("revision", "")) or None
        )
        if published_key
        else None
    )
    state = _output(editor_row)
    overlays = state.get("overlays")
    if isinstance(overlays, list):
        state["overlays"] = [
            {
                **dict(item),
                "image_url": storage.public_url(str(item["asset_key"])),
            }
            if isinstance(item, Mapping)
            and str(item.get("asset_key", "")).startswith(
                f"private/editor/{project_id}/"
            )
            else item
            for item in overlays
        ]
    editor = EditorState.model_validate(state) if state else None
    localization_output = _output(localization_row)
    localization = None
    if localization_row:
        localization = {
            "status": localization_row.get("status"),
            "error": localization_row.get("error_message"),
            "language": "hi",
            "language_name": "हिन्दी",
            "voice_id": localization_output.get("voice_id"),
            "captions": localization_output.get("captions", []),
            "translated_script": localization_output.get("translated_script", ""),
            "audio_url": storage.signed_url(str(localization_output["audio_key"]))
            if localization_output.get("audio_key")
            else None,
        }
    audio_tracks: dict[str, dict[str, object]] = {}
    for language, track in published_output.get("audio_tracks", {}).items():
        if not isinstance(track, Mapping) or not track.get("key"):
            continue
        audio_tracks[str(language)] = {
            "url": storage.published_url(
                str(track["key"]), str(track.get("revision", "")) or None
            ),
            "voice_url": storage.signed_url(str(track["audio_key"]))
            if track.get("audio_key")
            else None,
        }
    return GenerationResultResponse(
        status=project.status,
        stage=project.current_stage,
        progress=project.progress,
        final_url=published_url or preview_url,
        preview_url=preview_url,
        published_url=published_url,
        localization=localization,
        audio_tracks=audio_tracks,
        editor=editor,
        error=(
            hybrid_row.get("error_message")
            or published_row.get("error_message")
            or preview_row.get("error_message")
        )
        if project.status == "failed"
        else None,
    )


@router.patch("/project/{project_id}/editor", response_model=EditorState)
async def save_editor(
    project_id: UUID,
    body: EditorState,
    principal: Principal = Depends(require_admin),
    repository: ProjectRepository = Depends(project_repository),
) -> EditorState:
    await repository.get(project_id, None)
    await (
        repository.client.table("generation_jobs")
        .insert(
            {
                "project_id": str(project_id),
                "stage": "subtitles",
                "provider": "dramabyte-editor",
                "status": "completed",
                "output": body.model_dump(mode="json"),
            }
        )
        .execute()
    )
    return body


@router.post("/project/{project_id}/export", response_model=JobResponse)
async def export(
    project_id: UUID,
    body: EditorState,
    principal: Principal = Depends(require_admin),
    repository: ProjectRepository = Depends(project_repository),
) -> JobResponse:
    project = await repository.get(project_id, None)
    if project.production_mode == "dialogue_pilot":
        raise HTTPException(409, "Pilot is private review-only; publishing is disabled")
    await save_editor(project_id, body, principal, repository)
    await (
        repository.client.table("projects")
        .update({"status": "generating", "current_stage": "publish", "progress": 95})
        .eq("id", str(project_id))
        .execute()
    )
    job_id = str(uuid4())
    export_production.apply_async(
        args=[str(project_id)], task_id=job_id, queue="default"
    )
    return JobResponse(job_id=job_id)


@router.post("/script", response_model=ScriptResponse)
async def generate_script(
    body: GenerateScriptBody,
    _: Principal = Depends(require_admin),
) -> ScriptResponse:
    script = await DeepSeekScriptProvider().create_script(
        body.premise, body.language, body.duration_seconds
    )
    return ScriptResponse(script=script)


@router.post("/start", response_model=JobResponse)
async def start(
    body: StartGenerationBody,
    idempotency_key: str = Header(min_length=12, max_length=128),
    principal: Principal = Depends(require_admin),
    repository: ProjectRepository = Depends(project_repository),
) -> JobResponse:
    request = GenerationRequest(
        project_id=body.project_id,
        idempotency_key=idempotency_key,
        regenerate_from=body.regenerate_from,
    )
    job_id = await GenerationService(repository).enqueue(request, None)
    return JobResponse(job_id=job_id)
