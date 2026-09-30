from datetime import UTC, datetime
from typing import Any
from uuid import uuid4

import pytest

from app.application.history import HistoryService
from app.domain.history import HistoryError

USER = uuid4()


def row(index: int) -> dict[str, Any]:
    return {
        "episode_id": uuid4(),
        "series_id": uuid4(),
        "series_title": f"Series {index}",
        "episode_number": 1,
        "thumbnail": None,
        "position_seconds": 20,
        "duration_seconds": 60,
        "watched_at": datetime(2026, 1, index + 1, tzinfo=UTC),
    }


class FakeStore:
    def __init__(self, count: int = 0, result: str = "ok") -> None:
        self.data = [row(index) for index in range(count)]
        self.result = result
        self.recorded: list[tuple[int, int]] = []
        self.removed: list[Any] = []

    async def record(self, user_id, episode_id, position, max_rows):
        self.recorded.append((position, max_rows))
        return self.result

    async def rows(self, user_id, after, limit):
        return self.data[:limit]

    async def remove(self, user_id, episode_id):
        self.removed.append(episode_id)


async def test_record_passes_the_row_cap() -> None:
    store = FakeStore()
    await HistoryService(store, 200).record(USER, uuid4(), 30)
    assert store.recorded == [(30, 200)]


@pytest.mark.parametrize("code", ["episode_not_found", "user_unavailable"])
async def test_record_failures_raise(code: str) -> None:
    with pytest.raises(HistoryError) as caught:
        await HistoryService(FakeStore(result=code), 200).record(USER, uuid4(), 1)
    assert caught.value.code == code


async def test_page_paginates_and_normalises_missing_thumbnail() -> None:
    service = HistoryService(FakeStore(count=5), 200)
    page = await service.page(USER, None, 3)
    assert len(page.items) == 3
    assert page.next_cursor is not None
    assert page.items[0].thumbnail_url == ""
    last = await service.page(USER, None, 10)
    assert last.next_cursor is None


async def test_remove_one_and_clear_all() -> None:
    store = FakeStore()
    service = HistoryService(store, 200)
    target = uuid4()
    await service.remove(USER, target)
    await service.remove(USER, None)
    assert store.removed == [target, None]
