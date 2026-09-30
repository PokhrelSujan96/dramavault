from typing import Any
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.api.dependencies import comment_service
from app.application.comments import CommentService
from app.core.security import Principal, current_principal
from app.main import app

USER = str(uuid4())
EPISODE = str(uuid4())
COMMENT = str(uuid4())


class FakeStore:
    def __init__(self) -> None:
        self.code = "ok"
        self.calls = 0

    def _comment(self) -> dict[str, Any]:
        return {
            "id": COMMENT,
            "episode_id": EPISODE,
            "parent_id": None,
            "body": "hi",
            "created_at": "2026-01-01T00:00:00+00:00",
            "like_count": 0,
            "reply_count": 0,
            "liked": False,
            "author_id": USER,
            "author_name": "Sam",
            "author_avatar": None,
        }

    async def list_new(self, *args):
        return [self._comment()]

    async def list_top(self, *args):
        return [self._comment()]

    async def list_replies(self, *args):
        return []

    async def by_ids(self, *args):
        return [self._comment()]

    async def post(self, *args):
        self.calls += 1
        return {"code": self.code, "id": COMMENT}

    async def toggle_like(self, *args):
        return {"code": self.code, "like_count": 7}

    async def delete(self, *args):
        return self.code

    async def report(self, *args):
        return self.code


@pytest.fixture
def client():
    store = FakeStore()
    app.dependency_overrides[current_principal] = lambda: Principal(
        USER, "authenticated"
    )
    app.dependency_overrides[comment_service] = lambda: CommentService(store, 500, 10)
    yield TestClient(app), store
    app.dependency_overrides.clear()


def test_list_returns_a_page_with_ownership(client) -> None:
    http, _ = client
    response = http.get(f"/api/v1/comments/episodes/{EPISODE}?sort=new&limit=5")
    assert response.status_code == 200
    body = response.json()
    assert body["items"][0]["is_mine"] is True
    assert body["next_cursor"] is None


@pytest.mark.parametrize("query", ["sort=hot", "limit=0", "limit=51"])
def test_bad_list_parameters_are_rejected(client, query: str) -> None:
    http, _ = client
    assert http.get(f"/api/v1/comments/episodes/{EPISODE}?{query}").status_code == 422


def test_posting_creates_a_comment(client) -> None:
    http, store = client
    response = http.post(
        f"/api/v1/comments/episodes/{EPISODE}",
        json={"body": "Great episode", "idempotency_key": str(uuid4())},
    )
    assert response.status_code == 201
    assert response.json()["id"] == COMMENT
    assert store.calls == 1


@pytest.mark.parametrize(
    "payload",
    [{"body": ""}, {"body": "x" * 2001}, {"body": "ok", "parent_id": "nope"}],
)
def test_invalid_payloads_are_rejected_before_any_work(client, payload) -> None:
    http, store = client
    assert (
        http.post(f"/api/v1/comments/episodes/{EPISODE}", json=payload).status_code
        == 422
    )
    assert store.calls == 0


def test_too_long_after_cleaning_is_a_422(client) -> None:
    http, store = client
    response = http.post(
        f"/api/v1/comments/episodes/{EPISODE}", json={"body": "x" * 501}
    )
    assert response.status_code == 422
    assert store.calls == 0


def test_rate_limit_tells_the_client_when_to_retry(client) -> None:
    http, store = client
    store.code = "rate_limited"
    response = http.post(f"/api/v1/comments/episodes/{EPISODE}", json={"body": "hi"})
    assert response.status_code == 429
    assert response.headers["retry-after"] == "20"


@pytest.mark.parametrize(
    ("code", "status"),
    [("episode_not_found", 404), ("parent_not_found", 404), ("user_unavailable", 403)],
)
def test_domain_errors_map_to_http_statuses(client, code: str, status: int) -> None:
    http, store = client
    store.code = code
    response = http.post(f"/api/v1/comments/episodes/{EPISODE}", json={"body": "hi"})
    assert response.status_code == status


def test_like_delete_report_and_replies(client) -> None:
    http, store = client
    assert http.put(
        f"/api/v1/comments/{COMMENT}/like", json={"liked": True}
    ).json() == {"like_count": 7}
    assert http.get(f"/api/v1/comments/{COMMENT}/replies").json()["items"] == []
    assert (
        http.post(
            f"/api/v1/comments/{COMMENT}/report", json={"reason": "spam"}
        ).status_code
        == 204
    )
    assert http.delete(f"/api/v1/comments/{COMMENT}").status_code == 204
    store.code = "comment_not_found"
    assert http.delete(f"/api/v1/comments/{COMMENT}").status_code == 404


def test_comments_require_authentication() -> None:
    assert (
        TestClient(app).get(f"/api/v1/comments/episodes/{EPISODE}").status_code == 401
    )
