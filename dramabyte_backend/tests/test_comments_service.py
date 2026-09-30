from datetime import UTC, datetime
from typing import Any
from uuid import uuid4

import pytest

from app.application.comments import (
    CommentService,
    clean_body,
    decode_cursor,
    encode_cursor,
)
from app.domain.comments import CommentError

VIEWER = uuid4()
EPISODE = uuid4()


def row(index: int, author: Any = None, likes: int = 0) -> dict[str, Any]:
    return {
        "id": str(uuid4()),
        "episode_id": str(EPISODE),
        "parent_id": None,
        "body": f"comment {index}",
        "created_at": datetime(2026, 1, 1, 12, index, tzinfo=UTC).isoformat(),
        "like_count": likes,
        "reply_count": 0,
        "liked": False,
        "author_id": str(author or uuid4()),
        "author_name": "Sam",
        "author_avatar": None,
    }


class FakeStore:
    def __init__(self, rows: list[dict[str, Any]] | None = None) -> None:
        self.rows = rows or []
        self.calls: list[tuple[str, Any]] = []
        self.post_result: dict[str, Any] = {"code": "ok", "id": str(uuid4())}
        self.like_result: dict[str, Any] = {"code": "ok", "like_count": 4}
        self.delete_result = "ok"
        self.report_result = "ok"

    async def list_new(self, viewer, episode, after, limit):
        self.calls.append(("new", (after, limit)))
        return self.rows[:limit]

    async def list_top(self, viewer, episode, after, limit):
        self.calls.append(("top", (after, limit)))
        return self.rows[:limit]

    async def list_replies(self, viewer, parent, after, limit):
        self.calls.append(("replies", (after, limit)))
        return self.rows[:limit]

    async def by_ids(self, viewer, ids):
        return [{**row(1, author=viewer), "id": str(ids[0])}]

    async def post(self, user, episode, parent, body, key, max_per_minute, max_length):
        self.calls.append(("post", (body, parent, key, max_per_minute, max_length)))
        return self.post_result

    async def toggle_like(self, user, comment, liked):
        return self.like_result

    async def delete(self, user, comment):
        return self.delete_result

    async def report(self, user, comment, reason):
        self.calls.append(("report", reason))
        return self.report_result


def service(store: FakeStore) -> CommentService:
    return CommentService(store, 500, 10)


def test_body_cleaning_strips_control_characters_but_keeps_newlines() -> None:
    assert clean_body("  hi\x00 there\x07\nsecond line \t ") == "hi there\nsecond line"


def test_cursor_round_trip_and_tampering() -> None:
    token = encode_cursor(3, "2026-01-01T00:00:00+00:00", "abc")
    assert decode_cursor(token, 3) == ["3", "2026-01-01T00:00:00+00:00", "abc"]
    with pytest.raises(CommentError):
        decode_cursor(token, 2)
    with pytest.raises(CommentError):
        decode_cursor("!!not-base64!!", 2)


async def test_newest_page_reports_a_cursor_only_when_more_exist() -> None:
    store = FakeStore([row(i) for i in range(6)])
    page = await service(store).page(VIEWER, EPISODE, "new", None, 5)
    assert len(page.items) == 5
    assert page.next_cursor is not None
    last = await service(FakeStore([row(1)])).page(VIEWER, EPISODE, "new", None, 5)
    assert last.next_cursor is None
    assert store.calls[0] == ("new", (None, 6))


async def test_top_cursor_carries_likes_time_and_id_back_to_the_store() -> None:
    store = FakeStore([row(i, likes=10 - i) for i in range(4)])
    page = await service(store).page(VIEWER, EPISODE, "top", None, 3)
    assert page.next_cursor is not None
    await service(store).page(VIEWER, EPISODE, "top", page.next_cursor, 3)
    likes, created, identifier = store.calls[-1][1][0]
    assert likes == page.items[-1].like_count
    assert created == datetime.fromisoformat(page.items[-1].created_at.isoformat())
    assert str(identifier) == page.items[-1].id


async def test_bad_cursor_is_rejected_before_the_store() -> None:
    store = FakeStore()
    with pytest.raises(CommentError) as caught:
        await service(store).page(
            VIEWER, EPISODE, "top", encode_cursor("x", "y", "z"), 5
        )
    assert caught.value.code == "invalid_cursor"
    assert store.calls == []


async def test_own_comments_are_flagged_and_malformed_rows_skipped() -> None:
    store = FakeStore([row(1, author=VIEWER), {"broken": True}, row(2)])
    page = await service(store).page(VIEWER, EPISODE, "new", None, 10)
    assert [c.is_mine for c in page.items] == [True, False]


async def test_replies_paginate_oldest_first() -> None:
    store = FakeStore([row(i) for i in range(4)])
    page = await service(store).replies(VIEWER, uuid4(), None, 3)
    assert len(page.items) == 3 and page.next_cursor
    await service(store).replies(VIEWER, uuid4(), page.next_cursor, 3)
    assert store.calls[-1][1][0][1] is not None


async def test_post_sanitises_limits_and_returns_the_stored_comment() -> None:
    store = FakeStore()
    key, parent = uuid4(), uuid4()
    comment = await service(store).post(VIEWER, EPISODE, "  hello\x00 ", parent, key)
    assert store.calls[0] == ("post", ("hello", parent, key, 10, 500))
    assert comment.is_mine is True


@pytest.mark.parametrize("body", ["", "   ", "\x00\x01", "x" * 501])
async def test_invalid_bodies_never_reach_the_store(body: str) -> None:
    store = FakeStore()
    with pytest.raises(CommentError) as caught:
        await service(store).post(VIEWER, EPISODE, body, None, None)
    assert caught.value.code == "invalid_body"
    assert store.calls == []


@pytest.mark.parametrize(
    "code",
    ["rate_limited", "episode_not_found", "parent_not_found", "user_unavailable"],
)
async def test_store_rejections_surface_their_code(code: str) -> None:
    store = FakeStore()
    store.post_result = {"code": code}
    with pytest.raises(CommentError) as caught:
        await service(store).post(VIEWER, EPISODE, "hi", None, None)
    assert caught.value.code == code


async def test_like_delete_and_report_paths() -> None:
    store = FakeStore()
    svc = service(store)
    assert await svc.like(VIEWER, uuid4(), True) == 4
    await svc.delete(VIEWER, uuid4())
    await svc.report(VIEWER, uuid4(), "  spam\x00 ")
    assert store.calls[-1] == ("report", "spam")
    store.like_result = {"code": "comment_not_found"}
    store.delete_result = "comment_not_found"
    with pytest.raises(CommentError):
        await svc.like(VIEWER, uuid4(), True)
    with pytest.raises(CommentError):
        await svc.delete(VIEWER, uuid4())
    with pytest.raises(CommentError):
        await svc.report(VIEWER, uuid4(), "\x00")
