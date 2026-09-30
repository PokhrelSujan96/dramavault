from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from pydantic import ValidationError

from app.api.routes.editor_audio import VoiceReplacement, public_job
from app.application.editor_audio import EditorAudioRunner
from app.domain.narration_timing import TimedWord
from app.infrastructure import editor_audio_rendering as rendering


def test_voice_change_requires_explicit_paid_confirmation():
    with pytest.raises(ValidationError):
        VoiceReplacement(
            request_id="439f05ac-0c12-47a4-a4a9-3fced75589c8",
            reference_id="83c19893c4974594839bd2d101b1fd66",
            paid_confirmed=False,
        )


def test_voice_change_rejects_invalid_reference():
    with pytest.raises(ValidationError):
        VoiceReplacement(
            request_id="439f05ac-0c12-47a4-a4a9-3fced75589c8",
            reference_id="invalid",
            paid_confirmed=True,
        )


def test_audio_status_does_not_expose_storage_or_script():
    value = public_job(
        {
            "id": "job",
            "status": "completed",
            "input": {"reference_id": "voice", "script": "private"},
            "output": {"key": "private.mp4"},
        }
    )
    assert set(value) == {"id", "status", "reference_id", "error"}


def test_retime_preserves_caption_edits_and_style():
    old = [
        TimedWord(text="Hello", start=1, end=2),
        TimedWord(text="world", start=3, end=4),
    ]
    new = [
        TimedWord(text="Hello", start=0.5, end=1.5),
        TimedWord(text="world", start=2.5, end=4.5),
    ]
    state = {
        "captions": [{"id": 9, "text": "User edited text", "start": 1, "end": 4}],
        "style": {"font": "Poppins", "x": 0.3},
    }
    result = rendering.retime_captions(state, old, new, 5)
    assert result["captions"] == [
        {"id": 9, "text": "User edited text", "start": 0.5, "end": 4.5}
    ]
    assert result["style"] == state["style"]
    assert state["captions"][0]["start"] == 1


def test_retime_fails_with_missing_or_mismatching_alignment():
    with pytest.raises(ValueError):
        rendering.retime_captions({"captions": []}, [], [], 5)


def test_remux_stream_copies_footage_and_maps_only_new_voice(monkeypatch):
    monkeypatch.setattr(
        rendering, "duration", lambda path: 12 if path.name == "voice.mp3" else 10
    )
    monkeypatch.setattr(rendering, "_executable", lambda name: name)
    run = Mock()
    monkeypatch.setattr(rendering, "_run", run)
    rendering.fit_audio(Path("master.mp4"), Path("voice.mp3"), Path("new.mp4"))
    arguments = run.call_args.args[0]
    assert arguments[arguments.index("-c:v") + 1] == "copy"
    assert "0:v:0" in arguments and "1:a:0" in arguments
    assert "-stream_loop" not in arguments
    assert "atempo=1.200000000" in arguments[arguments.index("-af") + 1]


def test_unreasonable_pacing_does_not_replace_master(monkeypatch):
    monkeypatch.setattr(
        rendering, "duration", lambda path: 30 if path.name == "voice.mp3" else 10
    )
    run = Mock()
    monkeypatch.setattr(rendering, "_run", run)
    with pytest.raises(ValueError, match="pacing"):
        rendering.fit_audio(Path("master.mp4"), Path("voice.mp3"), Path("new.mp4"))
    run.assert_not_called()


@pytest.mark.parametrize("status", ["completed", "processing", "failed"])
def test_duplicate_delivery_never_repeats_paid_calls(status):
    client = Mock()
    query = client.table.return_value.select.return_value.eq.return_value
    query.single.return_value.execute.return_value = SimpleNamespace(
        data={"status": status}
    )
    runner = EditorAudioRunner(client)
    runner.replace = Mock()
    assert runner.run("job") == status
    runner.replace.assert_not_called()
