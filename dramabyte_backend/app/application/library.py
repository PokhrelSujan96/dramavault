from typing import Any, Protocol
from uuid import UUID

from pydantic import ValidationError

from app.domain.library import LibraryError, LibraryItem


class LibraryStore(Protocol):
    async def rows(self, user_id: UUID, limit: int) -> list[dict[str, Any]]: ...

    async def add(self, user_id: UUID, series_id: UUID, max_items: int) -> str: ...

    async def remove(self, user_id: UUID, series_id: UUID) -> None: ...


class LibraryService:
    def __init__(self, store: LibraryStore, max_items: int) -> None:
        self.store = store
        self.max_items = max_items

    async def items(self, user_id: UUID) -> list[LibraryItem]:
        items = []
        for row in await self.store.rows(user_id, self.max_items):
            try:
                items.append(LibraryItem.model_validate(row))
            except ValidationError:
                continue
        return items

    async def add(self, user_id: UUID, series_id: UUID) -> None:
        result = await self.store.add(user_id, series_id, self.max_items)
        if result != "ok":
            raise LibraryError(result)

    async def remove(self, user_id: UUID, series_id: UUID) -> None:
        await self.store.remove(user_id, series_id)
