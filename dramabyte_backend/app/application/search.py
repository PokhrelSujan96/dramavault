import re
from typing import Any, Protocol

from pydantic import ValidationError

from app.domain.home import SeriesCard


class SearchStore(Protocol):
    async def search(self, query: str, limit: int) -> list[dict[str, Any]]: ...


def normalize_query(query: str, max_length: int) -> str:
    return re.sub(r"\s+", " ", query).strip()[:max_length]


class SearchService:
    def __init__(self, store: SearchStore, min_length: int, max_length: int) -> None:
        self.store = store
        self.min_length = min_length
        self.max_length = max_length

    async def search(self, query: str, limit: int) -> list[SeriesCard]:
        term = normalize_query(query, self.max_length)
        if len(term) < self.min_length:
            return []
        cards = []
        for row in await self.store.search(term, limit):
            try:
                cards.append(SeriesCard.model_validate(row))
            except ValidationError:
                continue
        return cards
