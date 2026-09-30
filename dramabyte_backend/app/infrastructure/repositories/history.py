from datetime import datetime
from typing import Any
from uuid import UUID

from supabase import AsyncClient


class HistoryRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def record(
        self, user_id: UUID, episode_id: UUID, position: int, max_rows: int
    ) -> str:
        response = await self.client.rpc(
            "record_watch",
            {
                "p_user": str(user_id),
                "p_episode": str(episode_id),
                "p_position": position,
                "p_max_rows": max_rows,
            },
        ).execute()
        return str(response.data)

    async def rows(
        self, user_id: UUID, after: tuple[datetime, UUID] | None, limit: int
    ) -> list[dict[str, Any]]:
        response = await self.client.rpc(
            "list_watch_history",
            {
                "p_user": str(user_id),
                "p_after_watched": after[0].isoformat() if after else None,
                "p_after_episode": str(after[1]) if after else None,
                "p_limit": limit,
            },
        ).execute()
        data = response.data
        if not isinstance(data, list):
            return []
        return [row for row in data if isinstance(row, dict)]

    async def remove(self, user_id: UUID, episode_id: UUID | None) -> None:
        query = self.client.table("watch_history").delete().eq("user_id", str(user_id))
        if episode_id is not None:
            query = query.eq("episode_id", str(episode_id))
        await query.execute()
