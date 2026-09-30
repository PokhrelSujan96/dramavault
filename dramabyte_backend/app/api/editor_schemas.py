from typing import Literal

from pydantic import BaseModel, Field, model_validator


class CaptionItem(BaseModel):
    id: int = Field(ge=0)
    text: str = Field(max_length=500)
    start: float = Field(ge=0)
    end: float = Field(gt=0)

    @model_validator(mode="after")
    def valid_range(self) -> "CaptionItem":
        if self.end <= self.start:
            raise ValueError("Caption end must be after its start")
        return self


class CaptionStyle(BaseModel):
    animation: Literal["none", "fade", "pop"] = "none"
    font: str = Field(default="Poppins", pattern=r"^[\w -]{1,80}$")
    size: int = Field(default=54, ge=18, le=120)
    weight: str = Field(default="700", pattern=r"^(400|500|600|700|800|900)$")
    align: Literal["left", "center", "right"] = "center"
    color: str = Field(default="#ffffff", pattern=r"^#[0-9a-fA-F]{6}$")
    background: str = Field(default="#111111", pattern=r"^#[0-9a-fA-F]{6}$")
    background_opacity: float = Field(default=0.82, ge=0, le=1)
    x: float = Field(default=0.5, ge=0.05, le=0.95)
    y: float = Field(default=0.82, ge=0.05, le=0.95)
    max_width: float = Field(default=0.82, ge=0.25, le=0.95)
    template: str = Field(default="classic", max_length=40)
    italic: bool = False
    underline: bool = False
    outline: float = Field(default=0, ge=0, le=8)
    outline_color: str = Field(default="#000000", pattern=r"^#[0-9a-fA-F]{6}$")
    shadow: float = Field(default=0, ge=0, le=8)
    letter_spacing: float = Field(default=0, ge=-5, le=20)


class BackgroundMusic(BaseModel):
    track_id: str = Field(pattern=r"^[0-9a-fA-F-]{36}$")
    title: str = Field(min_length=1, max_length=200)
    creator: str = Field(min_length=1, max_length=200)
    source_url: str = Field(pattern=r"^https://", max_length=1000)
    audio_url: str = Field(pattern=r"^https://", max_length=1000)
    license: Literal["cc0", "by"]
    license_version: str = Field(default="", max_length=25)
    license_url: str = Field(pattern=r"^https://", max_length=500)
    attribution: str = Field(default="", max_length=2000)
    duration: float = Field(ge=0, le=3600)
    volume: float = Field(default=0.18, ge=0, le=1)
    fade_in: float = Field(default=1, ge=0, le=30)
    fade_out: float = Field(default=2, ge=0, le=30)
    start: float = Field(default=0, ge=0, le=180)


class EditorOverlay(BaseModel):
    id: str = Field(min_length=1, max_length=80)
    kind: Literal["text", "image"]
    text: str = Field(default="", max_length=500)
    asset_key: str = Field(default="", max_length=500)
    image_url: str = Field(default="", max_length=2000)
    x: float = Field(default=0.5, ge=0, le=1)
    y: float = Field(default=0.5, ge=0, le=1)
    width: float = Field(default=0.65, gt=0, le=1)
    height: float = Field(default=0.2, gt=0, le=1)
    opacity: float = Field(default=1, ge=0, le=1)
    start: float = Field(default=0, ge=0, le=3600)
    end: float = Field(default=5, gt=0, le=3600)
    style: CaptionStyle = Field(default_factory=CaptionStyle)

    @model_validator(mode="after")
    def valid_range(self) -> "EditorOverlay":
        if self.end <= self.start:
            raise ValueError("Overlay end must be after its start")
        return self


class SoundEffect(BaseModel):
    track_id: str = Field(pattern=r"^[0-9a-fA-F-]{36}$")
    title: str = Field(min_length=1, max_length=200)
    creator: str = Field(min_length=1, max_length=200)
    source_url: str = Field(pattern=r"^https://", max_length=1000)
    audio_url: str = Field(default="", pattern=r"^$|^https://", max_length=1000)
    license: Literal["cc0", "by"]
    license_version: str = Field(default="", max_length=25)
    license_url: str = Field(pattern=r"^https://", max_length=500)
    attribution: str = Field(default="", max_length=2000)
    duration: float = Field(ge=0, le=3600)
    start: float = Field(default=0, ge=0, le=3600)
    trim_start: float = Field(default=0, ge=0, le=3600)
    trim_end: float = Field(default=5, gt=0, le=3600)
    volume: float = Field(default=0.8, ge=0, le=1)
    fade_in: float = Field(default=0, ge=0, le=30)
    fade_out: float = Field(default=0, ge=0, le=30)

    @model_validator(mode="after")
    def valid_trim(self) -> "SoundEffect":
        if self.trim_end <= self.trim_start:
            raise ValueError("Sound-effect trim end must follow its start")
        return self


class EditorState(BaseModel):
    captions: list[CaptionItem] = Field(max_length=500)
    style: CaptionStyle = Field(default_factory=CaptionStyle)
    music: BackgroundMusic | None = None
    overlays: list[EditorOverlay] = Field(default_factory=list, max_length=30)
    sound_effects: list[SoundEffect] = Field(default_factory=list, max_length=20)
