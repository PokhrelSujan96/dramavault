from datetime import datetime
from typing import Any, Protocol
from uuid import UUID

from app.application.discover import decode_cursor, encode_cursor
from app.domain.history import HistoryError, HistoryItem, HistoryPage


class HistoryStore(Protocol):
    async def record(
        self, user_id: UUID, episode_id: UUID, position: int, max_rows: int
    ) -> str: ...

    async def rows(
        self, user_id: UUID, after: tuple[datetime, UUID] | None, limit: int
    ) -> list[dict[str, Any]]: ...

    async def remove(self, user_id: UUID, episode_id: UUID | None) -> None: ...


class HistoryService:
    def __init__(self, store: HistoryStore, max_rows: int) -> None:
        self.store = store
        self.max_rows = max_rows

    async def record(self, user_id: UUID, episode_id: UUID, position: int) -> None:
        result = await self.store.record(user_id, episode_id, position, self.max_rows)
        if result != "ok":
            raise HistoryError(result)

    async def page(self, user_id: UUID, cursor: str | None, limit: int) -> HistoryPage:
        after = decode_cursor(cursor) if cursor else None
        rows = await self.store.rows(user_id, after, limit + 1)
        visible = rows[:limit]
        last = visible[-1] if visible else None
        more = len(rows) > limit and last is not None
        return HistoryPage(
            items=[self._item(row) for row in visible],
            next_cursor=encode_cursor(str(last["watched_at"]), str(last["episode_id"]))
            if more and last
            else None,
        )

    async def remove(self, user_id: UUID, episode_id: UUID | None) -> None:
        await self.store.remove(user_id, episode_id)

    @staticmethod
    def _item(row: dict[str, Any]) -> HistoryItem:
        return HistoryItem(
            episode_id=str(row["episode_id"]),
            series_id=str(row["series_id"]),
            title=row["series_title"],
            episode_number=row["episode_number"],
            thumbnail_url=row["thumbnail"] or "",
            position_seconds=row["position_seconds"],
            duration_seconds=row["duration_seconds"],
            watched_at=row["watched_at"],
        )
