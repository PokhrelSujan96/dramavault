from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.api.dependencies import rating_service
from app.application.ratings import RatingService
from app.core.security import Principal, current_principal
from app.main import app

USER = str(uuid4())
TARGET = str(uuid4())


class FakeStore:
    def __init__(self) -> None:
        self.code = "ok"
        self.calls = 0

    async def rate(self, *args):
        self.calls += 1
        return {"code": self.code, "sum": 16, "count": 2, "my": args[3]}

    async def clear(self, *args):
        return {"code": self.code, "sum": 8, "count": 1, "my": None}

    async def series_totals(self, ids):
        return {}

    async def series_mine(self, user, series):
        return None


@pytest.fixture
def client():
    store = FakeStore()
    app.dependency_overrides[current_principal] = lambda: Principal(
        USER, "authenticated"
    )
    app.dependency_overrides[rating_service] = lambda: RatingService(store, 30)
    yield TestClient(app), store
    app.dependency_overrides.clear()


@pytest.mark.parametrize("kind", ["series", "episodes"])
def test_rating_and_clearing_return_the_new_summary(client, kind: str) -> None:
    http, _ = client
    rated = http.put(f"/api/v1/ratings/{kind}/{TARGET}", json={"rating": 9})
    assert rated.status_code == 200
    assert rated.json() == {"average": 8.0, "count": 2, "my_rating": 9}
    cleared = http.delete(f"/api/v1/ratings/{kind}/{TARGET}")
    assert cleared.json() == {"average": 8.0, "count": 1, "my_rating": None}


@pytest.mark.parametrize(
    "payload", [{"rating": 0}, {"rating": 11}, {"rating": "high"}, {}]
)
def test_invalid_ratings_are_rejected_before_any_work(client, payload) -> None:
    http, store = client
    assert http.put(f"/api/v1/ratings/series/{TARGET}", json=payload).status_code == 422
    assert store.calls == 0


def test_bad_ids_are_rejected(client) -> None:
    http, _ = client
    assert (
        http.put("/api/v1/ratings/series/not-a-uuid", json={"rating": 5}).status_code
        == 422
    )


@pytest.mark.parametrize(
    ("code", "status"),
    [("not_found", 404), ("user_unavailable", 403), ("rate_limited", 429)],
)
def test_domain_errors_map_to_http_statuses(client, code: str, status: int) -> None:
    http, store = client
    store.code = code
    response = http.put(f"/api/v1/ratings/episodes/{TARGET}", json={"rating": 5})
    assert response.status_code == status
    if code == "rate_limited":
        assert response.headers["retry-after"] == "30"


def test_ratings_require_authentication() -> None:
    assert (
        TestClient(app)
        .put(f"/api/v1/ratings/series/{TARGET}", json={"rating": 5})
        .status_code
        == 401
    )
