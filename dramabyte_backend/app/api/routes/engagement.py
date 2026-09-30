from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from postgrest.exceptions import APIError
from pydantic import BaseModel, Field

from app.api.routes.management import repository
from app.core.security import Principal, current_principal
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter()


class ViewBody(BaseModel):
    session_id: UUID
    watched_seconds: int = Field(ge=10, le=3600)


class LikeBody(BaseModel):
    liked: bool


class RatingBody(BaseModel):
    rating: int = Field(ge=1, le=10)


class CommentBody(BaseModel):
    body: str = Field(min_length=1, max_length=2000)


async def published_episode(
    repo: ManagementRepository, episode_id: UUID
) -> dict[str, Any]:
    episode = await repo.get("episodes", str(episode_id))
    project = await repo.get("projects", str(episode["project_id"]))
    if project["status"] != "published":
        raise HTTPException(404, "Episode not available")
    return episode


@router.post("/episodes/{episode_id}/views", status_code=204)
async def record_view(
    episode_id: UUID,
    body: ViewBody,
    principal: Principal = Depends(current_principal),
    repo: ManagementRepository = Depends(repository),
) -> None:
    episode = await published_episode(repo, episode_id)
    if body.watched_seconds > episode["duration_seconds"] + 5:
        raise HTTPException(422, "Watch time exceeds episode duration")
    try:
        await (
            repo.client.table("episode_views")
            .insert(
                {
                    "episode_id": str(episode_id),
                    "user_id": principal.user_id,
                    **body.model_dump(mode="json"),
                }
            )
            .execute()
        )
    except APIError as error:
        if error.code != "23505":
            raise


@router.post("/episodes/{episode_id}/likes", status_code=204)
async def like_episode(
    episode_id: UUID,
    body: LikeBody,
    principal: Principal = Depends(current_principal),
    repo: ManagementRepository = Depends(repository),
) -> None:
    await published_episode(repo, episode_id)
    values = {"episode_id": str(episode_id), "user_id": principal.user_id}
    if body.liked:
        await repo.client.table("episode_likes").upsert(values).execute()
    else:
        await (
            repo.client.table("episode_likes")
            .delete()
            .eq("episode_id", str(episode_id))
            .eq("user_id", principal.user_id)
            .execute()
        )


@router.post("/series/{series_id}/ratings", status_code=204)
async def rate_series(
    series_id: UUID,
    body: RatingBody,
    principal: Principal = Depends(current_principal),
    repo: ManagementRepository = Depends(repository),
) -> None:
    episode = (
        await repo.client.table("episodes")
        .select("projects!inner(status)")
        .eq("series_id", str(series_id))
        .eq("projects.status", "published")
        .limit(1)
        .execute()
    )
    if not episode.data:
        raise HTTPException(404, "Series not available")
    await (
        repo.client.table("series_ratings")
        .upsert(
            {
                "series_id": str(series_id),
                "user_id": principal.user_id,
                "rating": body.rating,
            }
        )
        .execute()
    )


@router.post("/episodes/{episode_id}/comments", status_code=201)
async def add_comment(
    episode_id: UUID,
    body: CommentBody,
    principal: Principal = Depends(current_principal),
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    await published_episode(repo, episode_id)
    if not body.body.strip():
        raise HTTPException(422, "Comment cannot be empty")
    return await repo.create(
        "episode_comments",
        {
            "episode_id": str(episode_id),
            "user_id": principal.user_id,
            "body": body.body.strip(),
        },
    )


@router.get("/episodes/{episode_id}/comments")
async def visible_comments(
    episode_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    await published_episode(repo, episode_id)
    result = (
        await repo.client.table("episode_comments")
        .select("id,body,created_at,profiles(display_name,avatar_url)")
        .eq("episode_id", str(episode_id))
        .eq("is_hidden", False)
        .order("created_at", desc=True)
        .limit(50)
        .execute()
    )
    return {"items": result.data}
