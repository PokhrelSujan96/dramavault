from typing import Any
from uuid import uuid4

import pytest

from app.application.series import SeriesService
from app.domain.series import SeriesError

SERIES = uuid4()


def episode(number: int) -> dict[str, Any]:
    return {
        "episode_id": str(uuid4()),
        "episode_number": number,
        "title": f"Ep {number}",
        "duration_seconds": 60,
        "thumbnail_url": "",
    }


def raw(free: int | None, count: int = 5) -> dict[str, Any]:
    return {
        "series_id": str(SERIES),
        "title": "True Beauty",
        "description": "desc",
        "genre": "Romance",
        "thumbnail_url": "poster.jpg",
        "free_episode_count": free,
        "episodes": [episode(n) for n in range(1, count + 1)],
    }


class FakeStore:
    def __init__(self, details: dict[str, Any] | None, rows: list | None = None):
        self.data = details
        self.rows = rows or []

    async def details(self, series_id):
        return self.data

    async def playlist(self, series_id):
        return self.rows


def service(store: FakeStore) -> SeriesService:
    return SeriesService(store, lambda key, revision=None: f"https://cdn/{key}")


async def test_all_episodes_are_free_when_no_limit_is_set() -> None:
    result = await service(FakeStore(raw(None))).details(SERIES)
    assert result.episode_count == 5
    assert result.free_episode_count is None
    assert not any(e.locked for e in result.episodes)


async def test_episodes_after_the_free_limit_are_locked() -> None:
    result = await service(FakeStore(raw(2))).details(SERIES)
    assert [e.locked for e in result.episodes] == [False, False, True, True, True]
    assert result.free_episode_count == 2


@pytest.mark.parametrize("data", [None, {**raw(None), "episodes": []}])
async def test_missing_or_empty_series_is_not_found(data) -> None:
    with pytest.raises(SeriesError) as caught:
        await service(FakeStore(data)).details(SERIES)
    assert caught.value.code == "series_not_found"


async def test_malformed_episodes_are_skipped() -> None:
    data = raw(None, count=2)
    data["episodes"].append({"broken": True})
    result = await service(FakeStore(data)).details(SERIES)
    assert result.episode_count == 2


async def test_playlist_signs_video_urls() -> None:
    row = {
        "series_id": SERIES,
        "episode_id": uuid4(),
        "series_title": "T",
        "series_description": "d",
        "genre": "G",
        "series_thumbnail": "s.jpg",
        "episode_number": 1,
        "episode_title": "",
        "episode_description": "",
        "episode_thumbnail": "",
        "duration_seconds": 60,
        "aspect_ratio": "9:16",
        "video_key": "videos/1.mp4",
        "video_revision": "r1",
        "published_count": 3,
        "likes": 0,
    }
    items = await service(FakeStore(raw(None), [row])).playlist(SERIES)
    assert items[0].video_url == "https://cdn/videos/1.mp4"
    assert items[0].episode_number == 1


async def test_playlist_passes_the_video_revision_to_the_signer() -> None:
    seen: list[tuple[str, str | None]] = []

    def signer(key: str, revision: str | None) -> str:
        seen.append((key, revision))
        return f"https://cdn/{key}?v={revision}"

    row = {
        "series_id": SERIES,
        "episode_id": uuid4(),
        "series_title": "T",
        "series_description": "d",
        "genre": "G",
        "series_thumbnail": "",
        "episode_number": 1,
        "episode_title": "",
        "episode_description": "",
        "episode_thumbnail": "",
        "duration_seconds": 60,
        "aspect_ratio": "9:16",
        "video_key": "videos/1.mp4",
        "video_revision": "r9",
        "published_count": 1,
        "likes": 0,
    }
    items = await SeriesService(FakeStore(None, [row]), signer).playlist(SERIES)
    assert seen == [("videos/1.mp4", "r9")]
    assert items[0].video_url.endswith("?v=r9")
