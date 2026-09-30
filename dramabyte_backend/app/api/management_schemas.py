from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class UserUpdate(BaseModel):
    display_name: str | None = Field(default=None, max_length=160)
    country: str | None = Field(default=None, max_length=80)
    language: str | None = Field(default=None, min_length=2, max_length=12)
    is_suspended: bool | None = None


class CoinAdjustment(BaseModel):
    amount: int = Field(ge=-1000000, le=1000000)
    reason: str = Field(min_length=3, max_length=500)
    request_id: UUID


class SeriesBody(BaseModel):
    title: str = Field(min_length=1, max_length=160)
    description: str = Field(default="", max_length=5000)
    thumbnail_url: str = Field(
        default="", max_length=2048, pattern=r"^(https://[^\s]+)?$"
    )
    genre: str = Field(default="Drama", min_length=1, max_length=80)
    target_episode_count: int = Field(default=15, ge=1, le=500)
    target_episode_seconds: int = Field(default=60, ge=10, le=600)


class EpisodeBody(BaseModel):
    project_id: UUID
    episode_number: int = Field(ge=1, le=100000)
    title: str = Field(default="", max_length=160)
    description: str = Field(default="", max_length=5000)
    thumbnail_url: str = Field(
        default="", max_length=2048, pattern=r"^(https://[^\s]+)?$"
    )
    duration_seconds: int = Field(default=60, ge=1, le=3600)


class VideoUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=160)
    premise: str | None = Field(default=None, max_length=2000)
    status: Literal["ready", "published"] | None = None
