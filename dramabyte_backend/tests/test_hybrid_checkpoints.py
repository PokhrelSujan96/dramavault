from pathlib import Path

import fal_client
import pytest

from app.infrastructure.hybrid_assets import HybridAssets


class Lease:
    def ensure(self) -> None:
        pass


class Store:
    def __init__(self) -> None:
        self.writes = []

    def update(self, table: str, identifier: str, values: dict) -> None:
        self.writes.append(values)


class Storage:
    def upload(self, path: Path, key: str, content_type: str) -> str:
        return key


def provider() -> HybridAssets:
    instance = object.__new__(HybridAssets)
    instance.store = Store()
    instance.lease = Lease()
    instance.storage = Storage()
    return instance


def test_existing_asset_does_not_call_provider(tmp_path, monkeypatch) -> None:
    def forbid(*args, **kwargs):
        pytest.fail("Cached assets must not create paid requests")

    monkeypatch.setattr(fal_client, "submit", forbid)
    assert (
        provider().image({"image_key": "existing.png"}, {}, "9:16", tmp_path)
        == "existing.png"
    )


def test_resume_retrieves_existing_request_without_resubmission(
    tmp_path, monkeypatch
) -> None:
    instance = provider()
    calls = []
    monkeypatch.setattr(HybridAssets, "_arguments", lambda *args: ("test-model", {}))

    def forbid(*args, **kwargs):
        pytest.fail("Resuming a known request must not submit another paid request")

    def result(endpoint: str, request_id: str):
        calls.append(request_id)
        return {"images": [{"url": "https://provider.example/image.png"}]}

    monkeypatch.setattr(fal_client, "submit", forbid)
    monkeypatch.setattr(
        fal_client, "status", lambda *args, **kwargs: fal_client.Completed(None, {})
    )
    monkeypatch.setattr(fal_client, "result", result)
    monkeypatch.setattr(
        "app.infrastructure.hybrid_assets.download",
        lambda url, path: path.write_bytes(b"image"),
    )
    key = instance.image(
        {
            "id": "shot",
            "shot_index": 0,
            "image_request_id": "existing-request",
            "image_pending": True,
        },
        {"id": "run"},
        "9:16",
        tmp_path,
    )
    assert "existing-request" in key
    assert calls == ["existing-request"]
    assert instance.store.writes[-1]["image_pending"] is False


def test_ambiguous_submission_cannot_spend_again(tmp_path, monkeypatch) -> None:
    monkeypatch.setattr(HybridAssets, "_arguments", lambda *args: ("test-model", {}))
    with pytest.raises(RuntimeError, match="Ambiguous"):
        provider().image({"image_pending": True}, {}, "9:16", tmp_path)
