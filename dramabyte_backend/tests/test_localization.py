from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from pydantic import ValidationError

from app.api.routes.localized_audio import HINDI_VOICES, HindiAudioRequest
from app.application.discover import to_discover_item
from app.application.hindi_audio import HindiAudioRunner
from app.application.localization import HindiTranslator
from app.infrastructure import editor_audio_rendering
from app.infrastructure.adapters.fish_audio import FishAudioProvider
from app.infrastructure.video_export import _filter_graph


def test_hindi_generation_requires_explicit_usage_confirmation() -> None:
    with pytest.raises(ValidationError):
        HindiAudioRequest(
            request_id="439f05ac-0c12-47a4-a4a9-3fced75589c8",
            voice_id="voice-id",
            paid_confirmed=False,
        )


def test_hindi_voice_choices_are_the_requested_male_and_female_ids() -> None:
    assert HINDI_VOICES == [
        {"id": "dcd006182803481390993aa6e9669207", "name": "Hindi storyteller · Male"},
        {
            "id": "83c19893c4974594839bd2d101b1fd66",
            "name": "Hindi storyteller · Female",
        },
    ]
    for voice in HINDI_VOICES:
        HindiAudioRequest(
            request_id="439f05ac-0c12-47a4-a4a9-3fced75589c8",
            voice_id=voice["id"],
            paid_confirmed=True,
        )


def test_hindi_voice_rejects_unconfigured_voice_id() -> None:
    with pytest.raises(ValidationError):
        HindiAudioRequest(
            request_id="439f05ac-0c12-47a4-a4a9-3fced75589c8",
            voice_id="another-voice",
            paid_confirmed=True,
        )


def test_duplicate_hindi_job_delivery_does_not_repeat_provider_calls(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    database = Mock()
    query = database.table.return_value.select.return_value.eq.return_value
    query.single.return_value.execute.return_value = SimpleNamespace(
        data={"status": "completed"}
    )
    runner = HindiAudioRunner(database)
    generate = Mock()
    monkeypatch.setattr(runner, "_generate", generate)
    assert runner.run("job") == "completed"
    generate.assert_not_called()


def test_translation_uses_configured_deepseek_and_returns_hindi(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr("app.application.localization.settings.deepseek_api_key", "key")
    response = Mock()
    response.json.return_value = {
        "choices": [{"message": {"content": "यह हिन्दी कहानी है।"}}]
    }
    request = Mock(return_value=response)
    monkeypatch.setattr("app.application.localization.httpx.post", request)
    assert HindiTranslator().translate("This is a story.") == "यह हिन्दी कहानी है।"
    request.assert_called_once()
    response.raise_for_status.assert_called_once()


def test_fish_synthesis_uses_requested_hindi_reference(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        "app.infrastructure.adapters.fish_audio.settings.fish_audio_api_key", "key"
    )
    response = Mock()
    response.content = b"mp3-data"
    request = Mock(return_value=response)
    monkeypatch.setattr("app.infrastructure.adapters.fish_audio.httpx.post", request)
    assert (
        FishAudioProvider().create_voice("नमस्ते", "83c19893c4974594839bd2d101b1fd66")
        == b"mp3-data"
    )
    assert request.call_args.kwargs["json"]["text"] == "नमस्ते"
    assert (
        request.call_args.kwargs["json"]["reference_id"]
        == "83c19893c4974594839bd2d101b1fd66"
    )
    assert request.call_args.kwargs["headers"]["model"] == "s2.1-pro-free"
    response.raise_for_status.assert_called_once()


def test_hindi_audio_tempo_fit_is_bounded(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(
        editor_audio_rendering,
        "duration",
        lambda path: 12 if path.name == "voice.mp3" else 10,
    )
    run = Mock()
    monkeypatch.setattr(editor_audio_rendering, "_run", run)
    editor_audio_rendering.fit_voice_track(
        Path("master.mp4"), Path("voice.mp3"), Path("fitted.mp3")
    )
    assert any("atempo=1.200000000" in argument for argument in run.call_args.args[0])


def test_export_mixes_localized_voice_instead_of_original_narration() -> None:
    graph, _, audio_map = _filter_graph(
        [],
        Path("captions.ass"),
        [],
        [(2, {"volume": 0.2}, "music")],
        1080,
        1920,
        60,
        narration_input=1,
    )
    assert "[1:a]" in graph
    assert "[0:a]" not in graph
    assert "amix=inputs=2" in graph
    assert audio_map == "[aout]"


def test_discover_item_signs_published_language_variants() -> None:
    row = {
        "series_id": "series",
        "episode_id": "episode",
        "series_title": "Series",
        "series_description": "Description",
        "episode_description": "Episode description",
        "genre": "Drama",
        "episode_thumbnail": "poster.jpg",
        "series_thumbnail": "",
        "episode_number": 1,
        "duration_seconds": 60,
        "aspect_ratio": "9:16",
        "video_key": "english.mp4",
        "video_revision": "en-revision",
        "video_variants": {"hi": {"key": "hindi.mp4", "revision": "hi-revision"}},
        "published_count": 1,
        "likes": 0,
    }
    item = to_discover_item(row, lambda key, revision: f"{key}?v={revision}")
    assert item.video_url == "english.mp4?v=en-revision"
    assert item.video_variants == {"hi": "hindi.mp4?v=hi-revision"}
