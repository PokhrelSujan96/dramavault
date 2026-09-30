from types import SimpleNamespace
from uuid import uuid4

import httpx
import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.api.routes.dialogue_actions import start_pilot
from app.api.routes.dialogue_pilots import PaidConsent
from app.core.config import settings
from app.domain.dialogue import PilotRequest, PilotShot, estimate
from app.domain.train_pilot import train_pilot
from app.infrastructure.adapters.fish_audio import FishAudioProvider
from app.infrastructure.dialogue_direction import (
    keyframe_prompt,
    lipsync_arguments,
    motion_arguments,
)
from app.infrastructure.dialogue_store import DialogueStore


def test_two_distinct_character_voices_required():
    body = {
        "series_id": str(uuid4()),
        "cast": [
            {"character_id": str(uuid4()), "voice_reference": "a" * 32},
            {"character_id": str(uuid4()), "voice_reference": "a" * 32},
        ],
    }
    with pytest.raises(ValidationError, match="distinct approved voice"):
        PilotRequest.model_validate(body)


def test_pilot_has_dialogue_reactions_and_consistent_set():
    plan = train_pilot("maya", "boy")
    assert len(plan.shots) == 8
    assert 20 <= sum(shot.seconds for shot in plan.shots) <= 35
    assert len([shot for shot in plan.shots if shot.role == "dialogue"]) == 4
    assert "Rain is outside only" in plan.continuity
    assert "dry teal seat" in plan.shots[4].action
    assert sum(estimate(plan).values()) < 5


def test_dialogue_has_only_one_visible_speaker():
    with pytest.raises(ValidationError, match="one visible"):
        PilotShot(
            index=0,
            role="dialogue",
            character_ids=["maya", "boy"],
            speaker_id="maya",
            text="Hello",
            action="Maya speaks calmly",
            camera="Close-up",
        )


def test_speaking_and_reaction_direction():
    plan = train_pilot("maya", "boy")
    speaking = motion_arguments(plan.shots[1], "image", 47)
    reaction = motion_arguments(plan.shots[2], "image", 47)
    assert speaking["resolution"] == "480p"
    assert speaking["enable_prompt_expansion"] is False
    assert "Keep lips closed" not in speaking["prompt"]
    assert "Keep lips closed" in reaction["prompt"]
    assert lipsync_arguments("video", "voice")["sync_mode"] == "cut_off"
    prompt = keyframe_prompt(
        plan,
        plan.shots[1],
        [
            {"id": "boy", "name": "Boy", "description": "wet red coat"},
        ],
    )
    assert "Reference 2 is the EMPTY set" in prompt
    assert "Reference 1 is Boy" in prompt
    assert "Do not redesign, recolor, exchange" in prompt
    assert "Show exactly 1 person" in prompt


def memory_store(budget=100):
    store = object.__new__(DialogueStore)
    store.row = {
        "id": "pilot",
        "budget_cents": budget,
        "reserved_cents": 0,
        "requests": {},
        "assets": {},
    }

    def save(**values):
        store.row.update(values)

    store.save = save
    return store


def test_allowances_reserved_once_and_enforced_before_submission():
    store = memory_store()
    first = store.reserve("motion-1", 20, {"prompt": "inside train"})
    assert store.reserve("motion-1", 20, {"prompt": "inside train"}) == first
    assert store.row["reserved_cents"] == 20
    with pytest.raises(ValueError, match="allowance reached"):
        store.reserve("expensive", 81, {})
    assert "expensive" not in store.row["requests"]


def test_changed_checkpoint_inputs_rejected():
    store = memory_store()
    store.reserve("motion-1", 20, {"prompt": "inside"})
    with pytest.raises(ValueError, match="inputs changed"):
        store.reserve("motion-1", 20, {"prompt": "outside"})


@pytest.mark.asyncio
async def test_paid_generation_disabled_before_database_access(monkeypatch):
    monkeypatch.setattr(settings, "dialogue_paid_enabled", False)
    with pytest.raises(HTTPException) as caught:
        await start_pilot(uuid4(), PaidConsent(paid_confirmed=True), SimpleNamespace())
    assert caught.value.status_code == 409
    assert "build-only" in caught.value.detail


def test_per_character_voice_does_not_change_narrator_default(monkeypatch):
    calls = []

    def post(url, **kwargs):
        calls.append(kwargs["json"]["reference_id"])
        return httpx.Response(200, content=b"voice", request=httpx.Request("POST", url))

    monkeypatch.setattr(httpx, "post", post)
    provider = FishAudioProvider()
    provider.create_voice("Maya speaks", "83c19893c4974594839bd2d101b1fd66")
    provider.create_voice("The boy speaks", "802e3bc2b27e49c2995d23ef70e6ac89")
    provider.create_voice("The narrator speaks")
    assert calls == [
        "83c19893c4974594839bd2d101b1fd66",
        "802e3bc2b27e49c2995d23ef70e6ac89",
        "dcd006182803481390993aa6e9669207",
    ]
