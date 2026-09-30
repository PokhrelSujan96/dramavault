import hashlib
import json
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator


class DialogueCast(BaseModel):
    model_config = ConfigDict(extra="forbid")
    character_id: UUID
    voice_reference: str = Field(pattern=r"^[a-f0-9]{32}$")


class PilotRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    series_id: UUID
    cast: list[DialogueCast] = Field(min_length=2, max_length=2)
    budget_usd: float = Field(default=5, ge=1, le=20, allow_inf_nan=False)
    template: Literal["train", "school"] = "train"

    @model_validator(mode="after")
    def distinct(self) -> "PilotRequest":
        if len({item.character_id for item in self.cast}) != 2:
            raise ValueError("Choose two different characters")
        if len({item.voice_reference for item in self.cast}) != 2:
            raise ValueError("Each character needs a distinct approved voice")
        return self


class PilotShot(BaseModel):
    model_config = ConfigDict(extra="forbid")
    index: int = Field(ge=0)
    role: Literal["establishing", "dialogue", "detail", "reaction"]
    character_ids: list[str] = Field(max_length=2)
    speaker_id: str | None = None
    text: str = Field(default="", max_length=200)
    action: str = Field(min_length=10, max_length=1000)
    camera: str = Field(min_length=5, max_length=400)
    seconds: float = Field(default=3, ge=1, le=5)
    voice_key: str | None = None
    words: list[dict[str, object]] = Field(default_factory=list)

    @model_validator(mode="after")
    def speaker(self) -> "PilotShot":
        if self.role == "dialogue":
            if not self.text or self.character_ids != [self.speaker_id]:
                raise ValueError("Dialogue requires one visible, assigned speaker")
        elif self.text or self.speaker_id:
            raise ValueError("Non-speaking shots cannot contain dialogue")
        return self


class PilotPlan(BaseModel):
    model_config = ConfigDict(extra="forbid")
    version: Literal["dialogue-pilot-v1"] = "dialogue-pilot-v1"
    title: str
    location: str
    continuity: str
    ambience: Literal["train", "school"] = "train"
    shots: list[PilotShot] = Field(min_length=2, max_length=10)

    @model_validator(mode="after")
    def ordered(self) -> "PilotPlan":
        if [shot.index for shot in self.shots] != list(range(len(self.shots))):
            raise ValueError("Pilot shots must have contiguous indexes")
        return self


def fingerprint(value: object) -> str:
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def estimate(plan: PilotPlan) -> dict[str, float]:
    dialogue = [shot for shot in plan.shots if shot.role == "dialogue"]
    return {
        "motion": round(len(plan.shots) * 0.20, 2),
        "lipsync": round(sum(shot.seconds for shot in dialogue) * 0.05, 2),
        "keyframe_allowance": round((len(plan.shots) + 1) * 0.10, 2),
        "voice_allowance": round(len(dialogue) * 0.15, 2),
    }
