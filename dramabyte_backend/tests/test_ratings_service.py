from typing import Any
from uuid import uuid4

import pytest

from app.application.ratings import RatingService
from app.domain.ratings import RatingError, average_rating

USER = uuid4()
TARGET = uuid4()


class FakeStore:
    def __init__(self) -> None:
        self.result: dict[str, Any] = {"code": "ok", "sum": 25, "count": 3, "my": 9}
        self.calls: list[tuple[Any, ...]] = []
        self.totals: dict[str, tuple[int, int]] = {}
        self.mine: int | None = None

    async def rate(self, kind, user, target, rating, max_per_minute):
        self.calls.append(("rate", kind, rating, max_per_minute))
        return self.result

    async def clear(self, kind, user, target):
        self.calls.append(("clear", kind))
        return {**self.result, "sum": 16, "count": 2, "my": None}

    async def series_totals(self, ids):
        return {i: self.totals[i] for i in ids if i in self.totals}

    async def series_mine(self, user, series):
        return self.mine


def service(store: FakeStore) -> RatingService:
    return RatingService(store, 30)


@pytest.mark.parametrize(
    ("total", "count", "expected"),
    [(0, 0, None), (25, 3, 8.3), (10, 1, 10.0), (17, 2, 8.5)],
)
def test_average_is_rounded_to_one_decimal(
    total: int, count: int, expected: float | None
) -> None:
    assert average_rating(total, count) == expected


async def test_rating_returns_the_updated_summary() -> None:
    store = FakeStore()
    summary = await service(store).rate("series", USER, TARGET, 9)
    assert (summary.average, summary.count, summary.my_rating) == (8.3, 3, 9)
    assert store.calls == [("rate", "series", 9, 30)]


@pytest.mark.parametrize("rating", [0, 11, -3])
async def test_out_of_range_ratings_never_reach_the_store(rating: int) -> None:
    store = FakeStore()
    with pytest.raises(RatingError) as caught:
        await service(store).rate("episode", USER, TARGET, rating)
    assert caught.value.code == "invalid_rating"
    assert store.calls == []


@pytest.mark.parametrize("code", ["rate_limited", "not_found", "user_unavailable"])
async def test_store_rejections_surface_their_code(code: str) -> None:
    store = FakeStore()
    store.result = {"code": code}
    with pytest.raises(RatingError) as caught:
        await service(store).rate("series", USER, TARGET, 5)
    assert caught.value.code == code


async def test_clearing_removes_my_rating_and_updates_the_average() -> None:
    summary = await service(FakeStore()).clear("episode", USER, TARGET)
    assert (summary.average, summary.count, summary.my_rating) == (8.0, 2, None)


async def test_series_summary_combines_totals_with_my_rating() -> None:
    store = FakeStore()
    store.totals[str(TARGET)] = (34, 4)
    store.mine = 7
    summary = await service(store).series_summary(TARGET, USER)
    assert (summary.average, summary.count, summary.my_rating) == (8.5, 4, 7)
    empty = await service(FakeStore()).series_summary(uuid4(), USER)
    assert (empty.average, empty.count, empty.my_rating) == (None, 0, None)


async def test_series_averages_for_home_cards() -> None:
    store = FakeStore()
    store.totals = {"a": (9, 1), "b": (0, 0)}
    result = await service(store).series_averages(["a", "b", "missing"])
    assert result["a"].average == 9.0
    assert result["b"].average is None
    assert "missing" not in result
    assert await service(store).series_averages([]) == {}
