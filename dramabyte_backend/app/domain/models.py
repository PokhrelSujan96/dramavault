from datetime import datetime
from enum import StrEnum
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class ProjectStatus(StrEnum):
    draft = "draft"
    queued = "queued"
    generating = "generating"
    review = "review"
    ready = "ready"
    published = "published"
    failed = "failed"


class PipelineStage(StrEnum):
    script = "script"
    storyboard = "storyboard"
    images = "images"
    video = "video"
    voice = "voice"
    subtitles = "subtitles"
    render = "render"
    publish = "publish"


class StoryProject(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    owner_id: UUID
    title: str = Field(min_length=1, max_length=160)
    premise: str = Field(default="", max_length=2000)
    script: str = Field(default="", max_length=50000)
    language: str = Field(default="en", max_length=12)
    aspect_ratio: str = "9:16"
    production_mode: str = "narrated"
    status: ProjectStatus = ProjectStatus.draft
    current_stage: PipelineStage = PipelineStage.script
    progress: int = Field(default=0, ge=0, le=100)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class GenerationRequest(BaseModel):
    project_id: UUID
    idempotency_key: str = Field(min_length=12, max_length=128)
    regenerate_from: PipelineStage | None = None
