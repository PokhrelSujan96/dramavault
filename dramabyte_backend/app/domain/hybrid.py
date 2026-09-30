import hashlib
import json
import math
import re
from collections.abc import Mapping, Sequence
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator, model_validator


class CharacterBody(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    description: str = Field(min_length=20, max_length=2000)


class Scene(BaseModel):
    index: int = Field(ge=0)
    narration: str = Field(min_length=1, max_length=5000)
    prompt: str = Field(min_length=20, max_length=3000)
    character_ids: list[UUID] = Field(default_factory=list, max_length=4)
    kind: Literal["motion", "still"] = "still"
    start: float = Field(default=0, ge=0)
    end: float = Field(default=5, gt=0)
    spec: "SceneSpec | None" = None


class SceneSpec(BaseModel):
    location: str = Field(min_length=5, max_length=400)
    setting: Literal["interior", "exterior", "mixed"]
    subject: str = Field(min_length=3, max_length=400)
    action: str = Field(min_length=5, max_length=800)
    camera: str = Field(min_length=3, max_length=300)
    camera_movement: str = Field(default="", max_length=300)
    crowd: str = Field(default="", max_length=600)
    required_details: list[str] = Field(min_length=1, max_length=12)
    forbidden_details: list[str] = Field(min_length=1, max_length=12)
    continuity: str = Field(min_length=10, max_length=1500)

    @field_validator("required_details", "forbidden_details", mode="before")
    @classmethod
    def as_list(cls, value: object) -> object:
        if isinstance(value, str):
            return [item.strip() for item in re.split(r"[;\n]+", value) if item.strip()]
        return value


class Storyboard(BaseModel):
    scenes: list[Scene] = Field(min_length=2, max_length=64)

    @model_validator(mode="after")
    def ordered(self) -> "Storyboard":
        if [scene.index for scene in self.scenes] != list(range(len(self.scenes))):
            raise ValueError("Scenes must have contiguous ordered indexes")
        return self


def shot_count(seconds: float) -> int:
    if not math.isfinite(seconds) or not 10 <= seconds <= 180:
        raise ValueError("Narration must last between 10 and 180 seconds")
    return max(2, math.ceil(seconds / 5))


def motion_budget(seconds: float, clips_per_minute: int = 8) -> int:
    if not math.isfinite(seconds) or seconds <= 0:
        raise ValueError("Episode duration must be positive")
    return max(2, math.ceil(seconds * clips_per_minute / 60))


def revision(
    script: str,
    aspect: str,
    cast: Sequence[Mapping[str, object]],
    voice_reference: str = "dcd006182803481390993aa6e9669207",
) -> str:
    value = json.dumps(
        ["budget-motion-v3", script, aspect, list(cast), voice_reference],
        sort_keys=True,
    )
    return hashlib.sha256(value.encode()).hexdigest()
