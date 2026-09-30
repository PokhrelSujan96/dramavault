from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query

from app.api.management_schemas import VideoUpdate
from app.api.routes.management import repository
from app.core.security import require_admin
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter(dependencies=[Depends(require_admin)])


@router.get("/videos")
async def videos(
    page: int = Query(1, ge=1),
    size: int = Query(25, ge=1, le=100),
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    return await repo.list("projects", page, size)


@router.patch("/videos/{project_id}")
async def update_video(
    project_id: UUID,
    body: VideoUpdate,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    project = await repo.get("projects", str(project_id))
    if project["status"] in {"queued", "generating"}:
        raise HTTPException(409, "Wait for production to finish")
    if body.status == "published":
        export = (
            await repo.client.table("generation_jobs")
            .select("id")
            .eq("project_id", str(project_id))
            .eq("provider", "dramabyte-published")
            .eq("status", "completed")
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )
        if not export.data:
            raise HTTPException(
                409, "Export this video in the editor before publishing"
            )
    return await repo.update(
        "projects", str(project_id), body.model_dump(exclude_none=True)
    )


@router.delete("/videos/{project_id}", status_code=204)
async def remove_video(
    project_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> None:
    project = await repo.get("projects", str(project_id))
    if project["status"] in {"queued", "generating"}:
        raise HTTPException(409, "Wait for production to finish")
    await repo.delete("projects", str(project_id))
