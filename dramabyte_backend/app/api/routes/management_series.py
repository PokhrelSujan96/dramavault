from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from postgrest.exceptions import APIError
from pydantic import BaseModel, Field

from app.api.routes.management import repository
from app.core.security import require_admin
from app.infrastructure.repositories.management import ManagementRepository

router = APIRouter(dependencies=[Depends(require_admin)])


class EpisodeOrder(BaseModel):
    episode_number: int | None = Field(default=None, ge=1, le=100000)
    title: str | None = Field(default=None, min_length=1, max_length=160)
    description: str | None = Field(default=None, max_length=5000)
    thumbnail_url: str | None = Field(
        default=None, max_length=2048, pattern=r"^(https://[^\s]+)?$"
    )
    duration_seconds: int | None = Field(default=None, ge=1, le=3600)


@router.patch("/episodes/{episode_id}")
async def reorder_episode(
    episode_id: UUID,
    body: EpisodeOrder,
    repo: ManagementRepository = Depends(repository),
) -> dict[str, Any]:
    try:
        return await repo.update(
            "episodes", str(episode_id), body.model_dump(exclude_none=True)
        )
    except APIError as error:
        raise HTTPException(409, "That episode number is already in use") from error


@router.delete("/series/{series_id}", status_code=204)
async def delete_series(
    series_id: UUID,
    repo: ManagementRepository = Depends(repository),
) -> None:
    await repo.delete("series", str(series_id))
