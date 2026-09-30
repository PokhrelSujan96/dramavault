from datetime import UTC, datetime
from typing import Any
from uuid import uuid4

import pytest

from app.application.library import LibraryService
from app.domain.library import LibraryError

USER = uuid4()


def row(name: str) -> dict[str, Any]:
    return {
        "series_id": name,
        "title": name,
        "genre": "Drama",
        "thumbnail_url": "",
        "episode_count": 3,
        "free_episode_count": None,
        "saved_at": datetime(2026, 1, 1, tzinfo=UTC).isoformat(),
    }


class FakeStore:
    def __init__(self, result: str = "ok") -> None:
        self.result = result
        self.added: list[int] = []
        self.removed: list[Any] = []
        self.limits: list[int] = []

    async def rows(self, user_id, limit):
        self.limits.append(limit)
        return [row("a"), {"broken": True}, row("b")]

    async def add(self, user_id, series_id, max_items):
        self.added.append(max_items)
        return self.result

    async def remove(self, user_id, series_id):
        self.removed.append(series_id)


async def test_items_are_capped_and_malformed_rows_skipped() -> None:
    store = FakeStore()
    items = await LibraryService(store, 200).items(USER)
    assert [i.title for i in items] == ["a", "b"]
    assert store.limits == [200]


async def test_add_passes_the_library_cap() -> None:
    store = FakeStore()
    await LibraryService(store, 150).add(USER, uuid4())
    assert store.added == [150]


@pytest.mark.parametrize(
    "code", ["series_not_found", "library_full", "user_unavailable"]
)
async def test_add_failures_raise(code: str) -> None:
    with pytest.raises(LibraryError) as caught:
        await LibraryService(FakeStore(code), 200).add(USER, uuid4())
    assert caught.value.code == code


async def test_remove_is_forwarded() -> None:
    store = FakeStore()
    target = uuid4()
    await LibraryService(store, 200).remove(USER, target)
    assert store.removed == [target]
