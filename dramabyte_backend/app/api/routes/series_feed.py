from collections.abc import Mapping
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends

from app.api.dependencies import project_repository
from app.api.routes.feed import published_feed
from app.infrastructure.repositories.projects import ProjectRepository

router = APIRouter()


@router.get("/series/{series_id}")
async def public_series(
    series_id: UUID,
    repository: ProjectRepository = Depends(project_repository),
) -> dict[str, Any]:
    episodes = (
        await repository.client.table("episodes")
        .select(
            "*,series(title,description,thumbnail_url,genre),projects!inner(status)"
        )
        .eq("series_id", str(series_id))
        .eq("projects.status", "published")
        .order("episode_number")
        .execute()
    )
    feed = await published_feed(repository)
    available = {str(item.id): item for item in feed.items}
    items = []
    details: Any = None
    for episode in episodes.data:
        if not isinstance(episode, Mapping):
            continue
        project = available.get(str(episode.get("project_id")))
        if project:
            details = episode.get("series")
            items.append(
                {
                    "episode_number": episode.get("episode_number"),
                    **project.model_dump(mode="json"),
                    "episode_id": str(episode.get("id")),
                    "title": episode.get("title") or project.title,
                    "description": episode.get("description") or project.premise,
                    "thumbnail_url": episode.get("thumbnail_url"),
                    "duration_seconds": episode.get("duration_seconds"),
                }
            )
    return {"id": str(series_id), "series": details, "items": items}
