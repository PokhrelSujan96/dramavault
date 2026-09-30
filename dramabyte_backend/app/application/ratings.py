from typing import Any, Literal, Protocol
from uuid import UUID

from app.domain.ratings import RatingError, RatingSummary, average_rating

Kind = Literal["series", "episode"]


class RatingStore(Protocol):
    async def rate(
        self, kind: Kind, user: UUID, target: UUID, rating: int, max_per_minute: int
    ) -> dict[str, Any]: ...

    async def clear(self, kind: Kind, user: UUID, target: UUID) -> dict[str, Any]: ...

    async def series_totals(self, ids: list[str]) -> dict[str, tuple[int, int]]: ...

    async def series_mine(self, user: UUID, series: UUID) -> int | None: ...


def _summary(result: dict[str, Any]) -> RatingSummary:
    if result.get("code") != "ok":
        raise RatingError(str(result.get("code", "unknown")))
    total, count = int(result.get("sum", 0)), int(result.get("count", 0))
    mine = result.get("my")
    return RatingSummary(
        average=average_rating(total, count),
        count=count,
        my_rating=int(mine) if mine is not None else None,
    )


class RatingService:
    def __init__(self, store: RatingStore, max_per_minute: int) -> None:
        self.store = store
        self.max_per_minute = max_per_minute

    async def rate(
        self, kind: Kind, user: UUID, target: UUID, rating: int
    ) -> RatingSummary:
        if not 1 <= rating <= 10:
            raise RatingError("invalid_rating")
        return _summary(
            await self.store.rate(kind, user, target, rating, self.max_per_minute)
        )

    async def clear(self, kind: Kind, user: UUID, target: UUID) -> RatingSummary:
        return _summary(await self.store.clear(kind, user, target))

    async def series_summary(self, series: UUID, user: UUID) -> RatingSummary:
        totals = await self.store.series_totals([str(series)])
        total, count = totals.get(str(series), (0, 0))
        return RatingSummary(
            average=average_rating(total, count),
            count=count,
            my_rating=await self.store.series_mine(user, series),
        )

    async def series_averages(self, ids: list[str]) -> dict[str, RatingSummary]:
        if not ids:
            return {}
        return {
            series: RatingSummary(average=average_rating(total, count), count=count)
            for series, (total, count) in (await self.store.series_totals(ids)).items()
        }
