from typing import Any

import pytest

from app.application.search import SearchService, normalize_query


def row(name: str) -> dict[str, Any]:
    return {"series_id": name, "title": name, "genre": "Drama", "episode_count": 3}


class FakeStore:
    def __init__(self) -> None:
        self.queries: list[tuple[str, int]] = []

    async def search(self, query: str, limit: int) -> list[dict[str, Any]]:
        self.queries.append((query, limit))
        return [row("a"), {"broken": True}, row("b")]


def service(store: FakeStore) -> SearchService:
    return SearchService(store, 2, 20)


@pytest.mark.parametrize("raw", ["", " ", "a", "  x  "])
async def test_too_short_queries_never_hit_the_database(raw: str) -> None:
    store = FakeStore()
    assert await service(store).search(raw, 10) == []
    assert store.queries == []


async def test_query_is_normalised_and_capped() -> None:
    store = FakeStore()
    await service(store).search("  love    story  " + "x" * 50, 10)
    query, limit = store.queries[0]
    assert query.startswith("love story x")
    assert len(query) == 20
    assert limit == 10


async def test_malformed_rows_are_skipped() -> None:
    cards = await service(FakeStore()).search("love", 10)
    assert [c.title for c in cards] == ["a", "b"]


def test_normalize_collapses_whitespace() -> None:
    assert normalize_query("a \t\n  b", 50) == "a b"
