from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException

from app.api.routes.dialogue_pilots import PaidConsent, PilotApproval
from app.api.routes.management import repository
from app.core.config import settings
from app.core.security import require_admin
from app.infrastructure.production_guard import production_guard
from app.infrastructure.queue.tasks import dialogue_pilot
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter(dependencies=[Depends(require_admin)])


@router.post("/pilots/{pilot_id}/start")
async def start_pilot(
    pilot_id: UUID,
    body: PaidConsent,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    if not body.paid_confirmed:
        raise HTTPException(422, "Explicit paid generation confirmation required")
    if not settings.dialogue_paid_enabled:
        raise HTTPException(409, "Paid pilot generation is disabled in build-only mode")
    row = await repo.get("dialogue_pilots", str(pilot_id))
    async with production_guard(row["project_id"]):
        row = await repo.get("dialogue_pilots", str(pilot_id))
        if row["state"] in {"queued", "voices", "video", "ready"}:
            return {"id": str(pilot_id), "state": row["state"]}
        if row["state"] == "review":
            names = [
                "location",
                *[f"image-{shot['index']}" for shot in row["plan"]["shots"]],
            ]
            if not all(row["approvals"].get(name) for name in names):
                raise HTTPException(409, "Approve every keyframe and set first")
        if row["state"] == "motion_review":
            names = [f"clip-{shot['index']}" for shot in row["plan"]["shots"]]
            if not all(row["approvals"].get(name) for name in names):
                raise HTTPException(409, "Approve every final motion clip first")
        await repo.update("dialogue_pilots", str(pilot_id), {"state": "queued"})
        await repo.update("projects", row["project_id"], {"status": "queued"})
        job_id = str(uuid4())
    try:
        dialogue_pilot.apply_async(
            args=[str(pilot_id)], task_id=job_id, queue="default"
        )
    except Exception as error:
        async with production_guard(row["project_id"]):
            await repo.update(
                "dialogue_pilots",
                str(pilot_id),
                {
                    "state": "failed",
                    "error_message": "Queue uncertain; inspect worker",
                },
            )
            await repo.update("projects", row["project_id"], {"status": "failed"})
        raise HTTPException(503, "Queue dispatch not confirmed") from error
    return {"id": str(pilot_id), "state": "queued", "job_id": job_id}


@router.patch("/pilots/{pilot_id}/approvals/{name}")
async def approve_pilot_asset(
    pilot_id: UUID,
    name: str,
    body: PilotApproval,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    row = await repo.get("dialogue_pilots", str(pilot_id))
    async with production_guard(row["project_id"]):
        row = await repo.get("dialogue_pilots", str(pilot_id))
        if row["state"] not in {"review", "motion_review", "failed"}:
            raise HTTPException(409, "Pilot is not in an editable review state")
        valid = {"location": "location"}
        for shot in row["plan"]["shots"]:
            index = shot["index"]
            valid[f"image-{index}"] = f"image-{index}"
            valid[f"clip-{index}"] = (
                f"lipsync-{index}" if shot["role"] == "dialogue" else f"motion-{index}"
            )
        if name not in valid or valid[name] not in row["assets"]:
            raise HTTPException(422, "Generate the requested asset before approval")
        if name.startswith("clip-") and row["state"] == "review":
            raise HTTPException(409, "Motion review has not started")
        return await repo.update(
            "dialogue_pilots",
            str(pilot_id),
            {
                "approvals": {**row["approvals"], name: body.approved},
            },
        )
