import fal_client
import pytest

from app.infrastructure.dialogue_assets import DialogueAssets
from app.infrastructure.dialogue_store import DialogueStore


def assets(tmp_path):
    store = object.__new__(DialogueStore)
    store.row = {
        "id": "pilot",
        "assets": {},
        "requests": {},
        "reserved_cents": 0,
        "budget_cents": 500,
    }

    def save(**values):
        store.row.update(values)

    store.save = save

    class Lease:
        def ensure(self):
            pass

    class Storage:
        def upload(self, path, key, content_type):
            return key

    instance = object.__new__(DialogueAssets)
    instance.store, instance.root = store, tmp_path
    instance.lease, instance.storage = Lease(), Storage()
    return instance


def forbid(*args, **kwargs):
    pytest.fail("This resume must not submit another paid request")


def test_cached_pilot_asset_never_calls_provider(tmp_path, monkeypatch):
    instance = assets(tmp_path)
    instance.store.row["assets"]["motion-0"] = "saved.mp4"
    monkeypatch.setattr(fal_client, "submit", forbid)
    assert instance.generate("motion-0", "model", {}, 20) == "saved.mp4"


def test_ambiguous_pilot_submission_blocks_retry(tmp_path, monkeypatch):
    instance = assets(tmp_path)
    instance.store.reserve("motion-0", 20, ["model", {}])
    monkeypatch.setattr(fal_client, "submit", forbid)
    with pytest.raises(RuntimeError, match="Ambiguous"):
        instance.generate("motion-0", "model", {}, 20)
    assert instance.store.row["reserved_cents"] == 20


def test_known_pilot_request_resumes_without_resubmission(tmp_path, monkeypatch):
    instance = assets(tmp_path)
    instance.store.reserve("motion-0", 20, ["model", {}])
    instance.store.request("motion-0", request_id="existing")
    monkeypatch.setattr(fal_client, "submit", forbid)
    monkeypatch.setattr(
        fal_client, "status", lambda *args: fal_client.Completed(None, {})
    )
    monkeypatch.setattr(
        fal_client, "result", lambda *args: {"video": {"url": "result"}}
    )
    monkeypatch.setattr(
        "app.infrastructure.dialogue_assets.download",
        lambda url, path: path.write_bytes(b"video"),
    )
    key = instance.generate("motion-0", "model", {}, 20)
    assert "existing" in key
    assert instance.store.row["reserved_cents"] == 20
    assert instance.store.row["requests"]["motion-0"]["pending"] is False
