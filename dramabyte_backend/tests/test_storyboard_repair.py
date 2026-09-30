from copy import deepcopy

import pytest

from app.domain.narration_timing import TimedBeat
from app.infrastructure.adapters.storyboard import StoryboardProvider


def board():
    return {
        "scenes": [
            {
                "index": i,
                "narration": text,
                "start": i * 2.5,
                "end": (i + 1) * 2.5,
                "kind": "motion",
                "character_ids": [],
                "prompt": "Classroom with anonymous background extras",
                "spec": {
                    "location": "School classroom",
                    "setting": "interior",
                    "subject": "Anonymous background extra",
                    "action": "Student glances across the aisle",
                    "camera": "Front angle",
                    "required_details": ["last desk"],
                    "forbidden_details": ["student behind final row"],
                    "continuity": "The same classroom and uniforms remain unchanged",
                },
            }
            for i, text in enumerate(["A student whispered.", "Mia looked down."])
        ]
    }


def beats():
    return [
        TimedBeat(index=i, narration=s["narration"], start=s["start"], end=s["end"])
        for i, s in enumerate(board()["scenes"])
    ]


def test_failed_review_is_repaired_and_reviewed_again(monkeypatch):
    replies = iter(
        [
            board(),
            {"passed": False, "issues": ["Impossible angle"]},
            board(),
            {"passed": True, "issues": []},
        ]
    )
    calls = []
    provider = StoryboardProvider()

    def request(system, payload):
        calls.append(payload)
        return next(replies)

    monkeypatch.setattr(provider, "_request", request)
    result = provider.plan("A student whispered. Mia looked down.", beats(), [])
    assert len(calls) == 4
    assert calls[2]["issues"] == ["Impossible angle"]
    assert result.scenes[1].start == 2.5


def test_persistently_bad_storyboard_still_stops(monkeypatch):
    responses = [
        board() if i % 2 == 0 else {"passed": False, "issues": ["Wrong set"]}
        for i in range(6)
    ]
    replies = iter(responses)
    provider = StoryboardProvider()
    monkeypatch.setattr(provider, "_request", lambda *args: next(replies))
    with pytest.raises(ValueError, match="after repairs"):
        provider.plan("Story", beats(), [])


def test_repair_cannot_change_narration_or_timestamps(monkeypatch):
    changed = deepcopy(board())
    changed["scenes"][0]["narration"] = "A different story."
    replies = iter([board(), {"passed": False, "issues": ["Wrong camera"]}, changed])
    provider = StoryboardProvider()
    monkeypatch.setattr(provider, "_request", lambda *args: next(replies))
    with pytest.raises(ValueError, match="aligned narration timeline"):
        provider.plan("Story", beats(), [])
