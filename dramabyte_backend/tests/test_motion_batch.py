import time
from pathlib import Path
from threading import Lock
from types import SimpleNamespace

import pytest

from app.application.motion_batch import generate_motion


def test_batch_has_at_most_two_requests_in_flight():
    counts = {"active": 0, "maximum": 0}
    lock = Lock()
    progress = []

    def video(*args):
        with lock:
            counts["active"] += 1
            counts["maximum"] = max(counts["maximum"], counts["active"])
        time.sleep(0.02)
        with lock:
            counts["active"] -= 1

    assets = SimpleNamespace(lease=SimpleNamespace(ensure=lambda: None), video=video)
    generate_motion(
        [{"kind": "motion"} for _ in range(5)],
        assets,
        {},
        "9:16",
        Path("."),
        progress.append,
    )
    assert counts["maximum"] == 2
    assert progress[-1] == 5


def test_failure_stops_submission_of_remaining_shots():
    started = []

    def video(shot, *args):
        started.append(shot["id"])
        raise RuntimeError("Provider failed")

    assets = SimpleNamespace(lease=SimpleNamespace(ensure=lambda: None), video=video)
    with pytest.raises(RuntimeError, match="Provider failed"):
        generate_motion(
            [{"kind": "motion", "id": i} for i in range(5)],
            assets,
            {},
            "9:16",
            Path("."),
            lambda count: None,
        )
    assert set(started).issubset({0, 1})


def test_still_timeline_submits_no_paid_request():
    assets = SimpleNamespace(lease=SimpleNamespace(ensure=lambda: None))
    generate_motion(
        [{"kind": "still"}], assets, {}, "9:16", Path("."), lambda count: None
    )
