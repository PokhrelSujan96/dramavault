from typing import Any

from app.application import home as home_module
from app.application.home import HomeService


def card(name: str) -> dict[str, Any]:
    return {
        "series_id": name,
        "title": name,
        "genre": "Drama",
        "episode_count": 3,
        "free_episode_count": 2,
        "views": 1250,
    }


class FakeStore:
    def __init__(self) -> None:
        self.calls = 0

    async def feed(self, limit: int) -> dict[str, Any]:
        self.calls += 1
        return {
            "featured": [card("a")],
            "trending": [card("b"), {"broken": True}],
            "genres": [
                {"genre": "Thriller", "items": [card("c")]},
                {"genre": "", "items": [card("x")]},
                "garbage",
            ],
        }


class Clock:
    now = 0.0

    def __call__(self) -> float:
        return self.now


def setup_function() -> None:
    home_module._CACHE.clear()


async def test_feed_skips_malformed_items_and_rails() -> None:
    feed = await HomeService(FakeStore(), 12, 60).feed()
    assert [c.title for c in feed.featured] == ["a"]
    assert [c.title for c in feed.trending] == ["b"]
    assert [g.genre for g in feed.genres] == ["Thriller"]
    assert feed.genres[0].items[0].thumbnail_url == ""
    assert feed.featured[0].free_episode_count == 2
    assert feed.featured[0].views == 1250
    assert feed.trending[0].views == 1250


async def test_feed_is_cached_until_the_ttl_expires() -> None:
    store, clock = FakeStore(), Clock()
    service = HomeService(store, 12, 60, clock)
    await service.feed()
    clock.now = 30
    await service.feed()
    assert store.calls == 1
    clock.now = 61
    await service.feed()
    assert store.calls == 2


async def test_empty_catalogue_returns_empty_feed() -> None:
    class Empty:
        async def feed(self, limit: int) -> dict[str, Any]:
            return {}

    feed = await HomeService(Empty(), 12, 0).feed()
    assert feed.featured == [] and feed.trending == [] and feed.genres == []


class FakeRatings:
    async def series_averages(self, ids):
        from app.domain.ratings import RatingSummary

        return {i: RatingSummary(average=8.4, count=12) for i in ids if i in {"a", "c"}}


async def test_home_cards_are_enriched_with_series_ratings() -> None:
    feed = await HomeService(FakeStore(), 12, 60, ratings=FakeRatings()).feed()
    assert (feed.featured[0].rating_average, feed.featured[0].rating_count) == (8.4, 12)
    assert feed.genres[0].items[0].rating_average == 8.4
    assert feed.trending[0].rating_average is None
    assert feed.trending[0].rating_count == 0
