from collections.abc import Mapping
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.api.routes.management import repository
from app.core.config import settings
from app.core.security import require_admin
from app.domain.hybrid import revision
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.production_guard import production_guard
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter(dependencies=[Depends(require_admin)])


class ApprovalBody(BaseModel):
    approved: bool


async def failure_reason(
    repo: ManagementRepository, project: dict[str, Any]
) -> str | None:
    if project["status"] != "failed":
        return None
    jobs = (
        await repo.client.table("generation_jobs")
        .select("error_message")
        .eq("project_id", str(project["id"]))
        .eq("status", "failed")
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )
    if not jobs.data or not isinstance(jobs.data[0], Mapping):
        return None
    return str(jobs.data[0]["error_message"] or "") or None


async def current_run(repo: ManagementRepository, project_id: str) -> dict[str, Any]:
    project = await repo.get("projects", project_id)
    error = await failure_reason(repo, project)
    episodes = (
        await repo.client.table("episodes")
        .select("series_id,episode_number")
        .eq("project_id", project_id)
        .execute()
    )
    if not episodes.data or not isinstance(episodes.data[0], Mapping):
        return {
            "run": None,
            "series_id": None,
            "characters": [],
            "project_status": project["status"],
            "error": error,
        }
    episode = dict(episodes.data[0])
    cast = (
        await repo.client.table("series_characters")
        .select("*")
        .eq("series_id", episode["series_id"])
        .order("id")
        .execute()
    )
    cast_rows = [dict(row) for row in cast.data if isinstance(row, Mapping)]
    fingerprint = revision(
        project["script"],
        project["aspect_ratio"],
        cast_rows,
        settings.fish_audio_reference_id,
    )
    runs = (
        await repo.client.table("production_runs")
        .select("*")
        .eq("project_id", project_id)
        .eq("revision", fingerprint)
        .execute()
    )
    return {
        **episode,
        "run": dict(runs.data[0])
        if runs.data and isinstance(runs.data[0], Mapping)
        else None,
        "characters": cast_rows,
        "project_status": project["status"],
        "error": error,
    }


@router.get("/project/{project_id}/hybrid")
async def hybrid_state(
    project_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    context = await current_run(repo, str(project_id))
    run = context["run"]
    if not run:
        return {**context, "shots": []}
    shots = (
        await repo.client.table("production_shots")
        .select("*")
        .eq("run_id", run["id"])
        .order("shot_index")
        .execute()
    )
    storage = R2Storage()
    return {
        **context,
        "shots": [
            {
                **dict(row),
                "image_url": storage.signed_url(str(row["image_key"]))
                if row["image_key"]
                else None,
                "video_url": storage.signed_url(str(row["video_key"]))
                if row["video_key"]
                else None,
            }
            for row in shots.data
            if isinstance(row, Mapping)
        ],
    }


async def editable_shot(
    project_id: UUID,
    shot_id: UUID,
    repo: ManagementRepository,
) -> dict[str, Any]:
    project = await repo.get("projects", str(project_id))
    if project["status"] not in {"review", "failed"}:
        raise HTTPException(
            409, "Shots can only be changed during review or after failure"
        )
    context = await current_run(repo, str(project_id))
    shot = await repo.get("production_shots", str(shot_id))
    if not context["run"] or shot["run_id"] != context["run"]["id"]:
        raise HTTPException(409, "Shot belongs to an outdated production revision")
    if context["run"]["master_key"]:
        raise HTTPException(409, "Completed production is immutable")
    return shot


@router.patch("/project/{project_id}/shots/{shot_id}/approval")
async def approve(
    project_id: UUID,
    shot_id: UUID,
    body: ApprovalBody,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    async with production_guard(str(project_id)):
        shot = await editable_shot(project_id, shot_id, repo)
        if not shot["image_key"]:
            raise HTTPException(409, "Generate the keyframe before approving")
        return await repo.update("production_shots", str(shot_id), body.model_dump())


@router.patch("/project/{project_id}/shots/{shot_id}/motion-approval")
async def approve_motion(
    project_id: UUID,
    shot_id: UUID,
    body: ApprovalBody,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    async with production_guard(str(project_id)):
        shot = await editable_shot(project_id, shot_id, repo)
        if not shot["video_key"]:
            raise HTTPException(409, "Generate motion before approving")
        return await repo.update(
            "production_shots",
            str(shot_id),
            {
                "motion_approved": body.approved,
            },
        )


@router.post("/project/{project_id}/shots/{shot_id}/reroll")
async def reroll(
    project_id: UUID,
    shot_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    async with production_guard(str(project_id)):
        return await reset_shot(project_id, shot_id, repo)


async def reset_shot(
    project_id: UUID, shot_id: UUID, repo: ManagementRepository
) -> dict[str, Any]:
    shot = await editable_shot(project_id, shot_id, repo)
    if shot["image_pending"] or shot["video_pending"]:
        raise HTTPException(409, "Reconcile the pending Fal request before rerolling")
    if shot["image_attempt"] >= settings.hybrid_max_rerolls_per_shot:
        raise HTTPException(
            409, "Reroll allowance used; review the character bible and script"
        )
    await repo.update("production_runs", str(shot["run_id"]), {"state": "images"})
    return await repo.update(
        "production_shots",
        str(shot_id),
        {
            "image_key": None,
            "video_key": None,
            "image_request_id": None,
            "video_request_id": None,
            "approved": False,
            "motion_approved": shot["kind"] == "still",
            "image_attempt": shot["image_attempt"] + 1,
            "image_model": None,
            "video_model": None,
        },
    )
