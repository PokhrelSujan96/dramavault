from typing import Any
from uuid import UUID

from supabase import AsyncClient


class LibraryRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def rows(self, user_id: UUID, limit: int) -> list[dict[str, Any]]:
        response = await self.client.rpc(
            "list_library", {"p_user": str(user_id), "p_limit": limit}
        ).execute()
        data = response.data
        if not isinstance(data, list):
            return []
        return [row for row in data if isinstance(row, dict)]

    async def add(self, user_id: UUID, series_id: UUID, max_items: int) -> str:
        response = await self.client.rpc(
            "add_to_library",
            {
                "p_user": str(user_id),
                "p_series": str(series_id),
                "p_max": max_items,
            },
        ).execute()
        return str(response.data)

    async def remove(self, user_id: UUID, series_id: UUID) -> None:
        await (
            self.client.table("library_items")
            .delete()
            .eq("user_id", str(user_id))
            .eq("series_id", str(series_id))
            .execute()
        )
