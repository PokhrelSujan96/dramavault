from types import SimpleNamespace

import pytest
from test_hybrid_pipeline import assets, spec

from app.api.routes.story_templates import school_template
from app.domain.last_seat_story import CAST, SCRIPT
from app.infrastructure.adapters.storyboard_prompts import DIRECTOR_PROMPT
from app.infrastructure.environment_assets import EnvironmentAssets, environment_id


@pytest.mark.asyncio
async def test_school_story_uses_only_storyteller_and_full_script():
    template = await school_template()
    assert template["audio_mode"] == "single_narrator"
    assert not template["music"] and not template["lipsync"]
    assert template["script"] == SCRIPT
    assert "secret that could change everything" in SCRIPT
    assert len(SCRIPT.split()) == 182
    assert len(CAST) == 4


def test_director_allows_extras_but_locks_named_cast():
    assert "Background extras" in DIRECTOR_PROMPT
    assert "three named cast characters" in DIRECTOR_PROMPT
    assert "reuse them verbatim" in DIRECTOR_PROMPT
    assert "do not request speaking mouths" in DIRECTOR_PROMPT.replace("\n", "")


def test_character_reference_precedes_shared_set():
    direction = spec()
    run = {
        "cast_snapshot": [
            {
                "id": "mia",
                "name": "Mia",
                "description": "Navy cardigan",
                "reference_key": "mia.png",
            }
        ],
        "environment_assets": {environment_id(direction["location"]): "corridor.png"},
    }
    _, arguments = assets()._arguments(
        {
            "id": "shot",
            "prompt": "Mia gathers books",
            "character_ids": ["mia"],
            "scene_spec": direction,
        },
        run,
        "9:16",
        "image",
    )
    assert arguments["image_urls"] == [
        "https://storage.example/mia.png",
        "https://storage.example/corridor.png",
    ]
    assert "Reference 2 is the EMPTY location plate" in arguments["prompt"]


def test_existing_environment_is_reused_without_provider_calls():
    instance = object.__new__(EnvironmentAssets)
    instance.lease = SimpleNamespace(ensure=lambda: pytest.fail("Unexpected paid path"))
    run = {"environment_assets": {environment_id("School corridor"): "set.png"}}
    instance.prepare(run, [{"scene_spec": {"location": "School corridor"}}], None)
    assert len(run["environment_assets"]) == 1


def test_environment_identifier_ignores_spacing_and_case():
    assert environment_id("SCHOOL  corridor") == environment_id("school corridor")
