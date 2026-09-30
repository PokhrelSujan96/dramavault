from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.api.editor_schemas import EditorState
from app.domain.models import PipelineStage, ProjectStatus, StoryProject
from app.domain.profile import Profile


class CreateProjectBody(BaseModel):
    title: str = Field(min_length=1, max_length=160)
    premise: str = Field(default="", max_length=2000)
    script: str = Field(default="", max_length=50000)
    language: str = Field(default="en", max_length=12)
    aspect_ratio: str = Field(default="9:16", pattern=r"^(9:16|16:9|1:1)$")


class ProjectResponse(BaseModel):
    project: StoryProject


class ProjectListResponse(BaseModel):
    items: list[StoryProject]


class StartGenerationBody(BaseModel):
    project_id: UUID
    regenerate_from: PipelineStage | None = None


class JobResponse(BaseModel):
    job_id: str
    status: ProjectStatus = ProjectStatus.queued


class SignInBody(BaseModel):
    email: str = Field(min_length=3, max_length=320)
    password: str = Field(min_length=8, max_length=128)


class SessionResponse(BaseModel):
    user_id: UUID
    email: str


class UpdateProjectBody(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=160)
    premise: str | None = Field(default=None, max_length=2000)
    script: str | None = Field(default=None, max_length=50000)
    language: str | None = Field(default=None, max_length=12)
    aspect_ratio: str | None = Field(
        default=None,
        pattern=r"^(9:16|16:9|1:1)$",
    )


class GenerateScriptBody(BaseModel):
    premise: str = Field(min_length=20, max_length=2000)
    language: str = Field(default="en", max_length=12)
    duration_seconds: int = Field(default=60, ge=15, le=180)


class ScriptResponse(BaseModel):
    script: str


class GenerationResultResponse(BaseModel):
    status: ProjectStatus
    stage: PipelineStage
    progress: int
    final_url: str | None = None
    preview_url: str | None = None
    published_url: str | None = None
    localization: dict[str, object] | None = None
    audio_tracks: dict[str, dict[str, object]] = Field(default_factory=dict)
    editor: EditorState | None = None
    error: str | None = None


class PublishedProjectResponse(BaseModel):
    id: UUID
    title: str
    premise: str
    language: str
    aspect_ratio: str
    video_url: str
    video_revision: str = ""
    video_variants: dict[str, str] = Field(default_factory=dict)


class PublishedFeedResponse(BaseModel):
    items: list[PublishedProjectResponse]


class GoogleSignInBody(BaseModel):
    id_token: str = Field(min_length=20, max_length=4096)
    referral_code: str | None = Field(default=None, pattern=r"^[A-Za-z0-9]{6,12}$")


class RefreshBody(BaseModel):
    refresh_token: str = Field(min_length=10, max_length=512)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    expires_in: int
    user_id: UUID


class ProfileResponse(BaseModel):
    id: UUID
    email: str | None
    display_name: str
    avatar_url: str | None
    country: str | None
    language: str
    coins: int
    bonus_coins: int
    is_vip: bool
    vip_expires_at: datetime | None
    is_onboarded: bool
    created_at: datetime

    @classmethod
    def from_domain(cls, profile: Profile) -> "ProfileResponse":
        expires = profile.vip_expires_at
        return cls(
            **profile.model_dump(exclude={"auth_provider", "last_login_at"}),
            is_vip=expires is not None and expires > datetime.now(expires.tzinfo),
        )


class CreateOrderBody(BaseModel):
    package_id: str = Field(pattern=r"^[a-z0-9_]{3,40}$")


class ConfirmOrderBody(BaseModel):
    receipt: str | None = Field(default=None, max_length=8192)
