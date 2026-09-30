from collections.abc import Mapping
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from postgrest.exceptions import APIError

from app.api.management_schemas import EpisodeBody, SeriesBody
from app.api.routes.management import repository
from app.core.security import require_admin
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter(dependencies=[Depends(require_admin)])


@router.get("/series")
async def series(repo: ManagementRepository = Depends(repository)) -> dict[str, Any]:
    return await repo.list("series_metrics", 1, 100)


@router.post("/series", status_code=201)
async def create_series(
    body: SeriesBody,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    return await repo.create("series", body.model_dump())


@router.patch("/series/{series_id}")
async def edit_series(
    series_id: UUID,
    body: SeriesBody,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    return await repo.update("series", str(series_id), body.model_dump())


@router.get("/series/{series_id}/episodes")
async def episodes(
    series_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    result = (
        await repo.client.table("episodes")
        .select("*,projects(*)")
        .eq("series_id", str(series_id))
        .order("episode_number")
        .execute()
    )
    metrics = (
        await repo.client.table("episode_metrics")
        .select("id,views,likes,comments")
        .eq("series_id", str(series_id))
        .execute()
    )
    counts = {
        str(row["id"]): dict(row) for row in metrics.data if isinstance(row, Mapping)
    }
    return {
        "items": [
            {**dict(row), **counts.get(str(row["id"]), {})}
            for row in result.data
            if isinstance(row, Mapping)
        ]
    }


@router.post("/series/{series_id}/episodes", status_code=201)
async def add_episode(
    series_id: UUID,
    body: EpisodeBody,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    await repo.get("series", str(series_id))
    project = await repo.get("projects", str(body.project_id))
    try:
        return await repo.create(
            "episodes",
            {
                **body.model_dump(mode="json"),
                "title": body.title or project["title"],
                "description": body.description or project["premise"],
                "series_id": str(series_id),
            },
        )
    except APIError as error:
        raise HTTPException(
            409, "Episode number or project is already assigned"
        ) from error


@router.delete("/episodes/{episode_id}", status_code=204)
async def remove_episode(
    episode_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> None:
    await repo.delete("episodes", str(episode_id))
