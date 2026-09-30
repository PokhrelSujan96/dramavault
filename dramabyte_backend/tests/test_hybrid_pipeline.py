from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.domain.hybrid import Scene, Storyboard, motion_budget, revision, shot_count
from app.infrastructure.hybrid_assets import HybridAssets


def board(count: int = 12) -> Storyboard:
    return Storyboard(
        scenes=[
            Scene(
                index=index,
                narration=f"Scene {index}",
                prompt="Cinematic train scene with natural film lighting",
                kind="motion",
            )
            for index in range(count)
        ]
    )


def test_one_minute_has_twelve_distinct_shots() -> None:
    assert shot_count(60) == 12
    assert all(scene.kind == "motion" for scene in board().scenes)


def test_one_minute_budget_allows_eight_motion_clips() -> None:
    assert motion_budget(60) == 8
    assert motion_budget(30) == 4


@pytest.mark.parametrize("seconds", [0, 9, 181, float("nan"), float("inf")])
def test_invalid_narration_duration_rejected(seconds: float) -> None:
    with pytest.raises(ValueError):
        shot_count(seconds)


def test_storyboard_accepts_static_shots() -> None:
    scene = Scene(
        index=0,
        narration="The train moves",
        prompt="A cinematic moving train",
        kind="still",
    )
    assert scene.kind == "still"


def test_changed_script_or_character_creates_new_revision() -> None:
    cast = [
        {"id": str(uuid4()), "description": "Red coat", "reference_key": "portrait"}
    ]
    original = revision("Story", "9:16", cast)
    assert original == revision("Story", "9:16", cast)
    assert original != revision("Changed story", "9:16", cast)
    assert original != revision("Story", "9:16", [{**cast[0], "reference_key": "new"}])


def test_storyboard_requires_ordered_indexes() -> None:
    with pytest.raises(ValidationError):
        Storyboard(scenes=[board(2).scenes[1], board(2).scenes[0]])


class Storage:
    def signed_url(self, key: str) -> str:
        return f"https://storage.example/{key}"


def assets() -> HybridAssets:
    instance = object.__new__(HybridAssets)
    instance.storage = Storage()
    from app.infrastructure.adapters.fal import FalMediaProvider

    instance.media = object.__new__(FalMediaProvider)
    return instance


def spec() -> dict:
    return {
        "location": "Inside an enclosed dry train carriage",
        "setting": "interior",
        "subject": "The boy in his red raincoat",
        "action": "Show soaked coat and dry seat",
        "camera": "Close-up",
        "required_details": ["wet fabric", "dry upholstery"],
        "forbidden_details": ["rain falling inside", "outdoor bench", "wet seat"],
        "continuity": "Boy remains inside the enclosed train. Rain is outside the windows.",
    }


def test_character_shots_use_reference_images() -> None:
    instance = assets()
    shot = {
        "id": "shot",
        "prompt": "Maya enters train",
        "character_ids": ["maya"],
        "scene_spec": spec(),
    }
    cast = [
        {
            "id": "maya",
            "name": "Maya",
            "description": "Red coat",
            "reference_key": "maya.png",
        }
    ]
    endpoint, arguments = instance._arguments(
        shot, {"cast_snapshot": cast}, "9:16", "image"
    )
    assert endpoint == "fal-ai/flux-2/klein/4b/edit"
    assert arguments["image_urls"] == ["https://storage.example/maya.png"]
    assert "Red coat" in arguments["prompt"]


def test_motion_is_always_480p_default_frames() -> None:
    endpoint, arguments = assets()._arguments(
        {
            "id": "shot",
            "prompt": "Train moves",
            "image_key": "shot.png",
            "scene_spec": spec(),
        },
        {},
        "9:16",
        "video",
    )
    assert endpoint == "fal-ai/wan-i2v"
    assert arguments["resolution"] == "480p"
    assert arguments["num_frames"] == 81
    assert arguments["frames_per_second"] == 16


def test_reroll_changes_seed() -> None:
    instance = assets()
    shot = {
        "id": "shot",
        "prompt": "Empty train scene",
        "character_ids": [],
        "scene_spec": spec(),
    }
    _, first = instance._arguments(shot, {"cast_snapshot": []}, "9:16", "image")
    _, second = instance._arguments(
        {**shot, "image_attempt": 1}, {"cast_snapshot": []}, "9:16", "image"
    )
    assert first["seed"] != second["seed"]


def test_scene_spec_accepts_delimited_detail_strings():
    from app.domain.hybrid import SceneSpec

    spec = SceneSpec.model_validate(
        {
            "location": "Bright school corridor",
            "setting": "interior",
            "subject": "Ellie",
            "action": "Walks past lockers",
            "camera": "wide",
            "required_details": "navy blazer; burgundy tie",
            "forbidden_details": ["text"],
            "continuity": "Same corridor as the previous shot.",
        }
    )
    assert spec.required_details == ["navy blazer", "burgundy tie"]
