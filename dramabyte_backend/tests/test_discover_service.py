from datetime import UTC, datetime
from typing import Any
from uuid import uuid4

import pytest

from app.application.discover import DiscoverService, decode_cursor, encode_cursor
from app.domain.discover import DiscoverError


def row(index: int) -> dict[str, Any]:
    return {
        "series_id": uuid4(),
        "series_created_at": datetime(2026, 1, index + 1, tzinfo=UTC).isoformat(),
        "series_title": f"Series {index}",
        "series_description": "series text",
        "genre": "Drama",
        "series_thumbnail": "series.jpg",
        "episode_id": uuid4(),
        "episode_number": 1,
        "episode_title": "",
        "episode_description": "",
        "episode_thumbnail": "",
        "duration_seconds": 60,
        "aspect_ratio": "9:16",
        "video_key": f"videos/{index}.mp4",
        "published_count": 9,
        "likes": 3,
    }


class FakeStore:
    def __init__(self, count: int) -> None:
        self.data = [row(index) for index in range(count)]
        self.requested: list[int] = []

    async def rows(self, after, limit):
        self.requested.append(limit)
        return self.data[:limit]


def service(count: int) -> tuple[DiscoverService, FakeStore]:
    store = FakeStore(count)
    return DiscoverService(
        store, lambda key, revision=None: f"https://cdn/{key}"
    ), store


async def test_full_page_has_next_cursor_and_signed_urls() -> None:
    svc, store = service(10)
    page = await svc.page(None, 6)
    assert store.requested == [7]
    assert len(page.items) == 6
    assert page.next_cursor is not None
    assert page.items[0].video_url == "https://cdn/videos/0.mp4"
    assert page.items[0].description == "series text"
    assert page.items[0].thumbnail_url == "series.jpg"


async def test_last_page_has_no_cursor() -> None:
    svc, _ = service(4)
    page = await svc.page(None, 6)
    assert len(page.items) == 4
    assert page.next_cursor is None


def test_cursor_round_trips() -> None:
    identifier = uuid4()
    created = datetime(2026, 1, 1, tzinfo=UTC)
    assert decode_cursor(encode_cursor(created.isoformat(), str(identifier))) == (
        created,
        identifier,
    )


@pytest.mark.parametrize("cursor", ["not-a-cursor", "YQ=="])
async def test_invalid_cursor_is_rejected(cursor: str) -> None:
    svc, _ = service(1)
    with pytest.raises(DiscoverError):
        await svc.page(cursor, 6)
