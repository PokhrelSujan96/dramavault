import time
from collections.abc import Callable
from typing import Any, Protocol

from pydantic import ValidationError

from app.domain.home import GenreRail, HomeFeed, SeriesCard
from app.domain.ratings import RatingSummary

_CACHE: dict[str, tuple[float, HomeFeed]] = {}


class HomeStore(Protocol):
    async def feed(self, limit: int) -> dict[str, Any]: ...


class SeriesRatings(Protocol):
    async def series_averages(self, ids: list[str]) -> dict[str, RatingSummary]: ...


def _cards(raw: Any) -> list[SeriesCard]:
    cards = []
    for item in raw if isinstance(raw, list) else []:
        try:
            cards.append(SeriesCard.model_validate(item))
        except ValidationError:
            continue
    return cards


class HomeService:
    def __init__(
        self,
        store: HomeStore,
        limit: int,
        ttl_seconds: float,
        clock: Callable[[], float] = time.monotonic,
        ratings: SeriesRatings | None = None,
    ) -> None:
        self.store = store
        self.limit = limit
        self.ttl = ttl_seconds
        self.clock = clock
        self.ratings = ratings

    async def feed(self) -> HomeFeed:
        cached = _CACHE.get("home")
        if cached and self.clock() - cached[0] < self.ttl:
            return cached[1]
        raw = await self.store.feed(self.limit)
        genres = raw.get("genres")
        feed = HomeFeed(
            featured=_cards(raw.get("featured")),
            trending=_cards(raw.get("trending")),
            genres=[
                GenreRail(genre=str(rail["genre"]), items=_cards(rail.get("items")))
                for rail in (genres if isinstance(genres, list) else [])
                if isinstance(rail, dict) and rail.get("genre")
            ],
        )
        feed = await self._rated(feed)
        _CACHE["home"] = (self.clock(), feed)
        return feed

    async def _rated(self, feed: HomeFeed) -> HomeFeed:
        if self.ratings is None:
            return feed
        ids = {c.series_id for c in feed.featured + feed.trending}
        ids |= {c.series_id for rail in feed.genres for c in rail.items}
        found = await self.ratings.series_averages(sorted(ids))

        def rate(card: SeriesCard) -> SeriesCard:
            summary = found.get(card.series_id)
            if summary is None:
                return card
            return card.model_copy(
                update={
                    "rating_average": summary.average,
                    "rating_count": summary.count,
                }
            )

        return HomeFeed(
            featured=[rate(c) for c in feed.featured],
            trending=[rate(c) for c in feed.trending],
            genres=[
                GenreRail(genre=rail.genre, items=[rate(c) for c in rail.items])
                for rail in feed.genres
            ],
        )
