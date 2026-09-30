from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.api.dependencies import engagement_service
from app.application.engagement import EngagementService
from app.core.security import Principal, current_principal
from app.main import app

USER = str(uuid4())


class FakeStore:
    def __init__(self) -> None:
        self.result = "ok"
        self.calls = 0

    async def stats(self, episode_ids, user_id):
        return {}

    async def record_views(self, *args):
        self.calls += 1
        return self.result


@pytest.fixture
def client():
    store = FakeStore()
    app.dependency_overrides[current_principal] = lambda: Principal(
        USER, "authenticated"
    )
    app.dependency_overrides[engagement_service] = lambda: EngagementService(
        store, 50, 100, 120
    )
    yield TestClient(app), store
    app.dependency_overrides.clear()


def body(**overrides):
    data = {
        "batch_id": str(uuid4()),
        "items": [{"episode_id": str(uuid4()), "count": 3}],
    }
    data.update(overrides)
    return data


def test_valid_batch_is_accepted(client) -> None:
    http, store = client
    assert http.post("/api/v1/views/batch", json=body()).status_code == 204
    assert store.calls == 1


def test_duplicate_batch_is_still_a_success(client) -> None:
    http, store = client
    store.result = "duplicate"
    assert http.post("/api/v1/views/batch", json=body()).status_code == 204


def test_rate_limiting_tells_the_client_when_to_retry(client) -> None:
    http, store = client
    store.result = "rate_limited"
    response = http.post("/api/v1/views/batch", json=body())
    assert response.status_code == 429
    assert response.headers["retry-after"] == "30"


@pytest.mark.parametrize(
    "payload",
    [
        body(items=[]),
        body(items=[{"episode_id": str(uuid4()), "count": 0}]),
        body(items=[{"episode_id": str(uuid4()), "count": 101}]),
        body(items=[{"episode_id": str(uuid4()), "count": 1}] * 51),
        body(items=[{"episode_id": "not-a-uuid", "count": 1}]),
        body(batch_id="nope"),
    ],
)
def test_oversized_or_malformed_batches_are_rejected_before_any_work(
    client, payload
) -> None:
    http, store = client
    assert http.post("/api/v1/views/batch", json=payload).status_code == 422
    assert store.calls == 0


def test_views_require_authentication() -> None:
    assert TestClient(app).post("/api/v1/views/batch", json=body()).status_code == 401
