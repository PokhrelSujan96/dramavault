from typing import Any

from supabase import AsyncClient


class SearchRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def search(self, query: str, limit: int) -> list[dict[str, Any]]:
        response = await self.client.rpc(
            "search_series", {"p_query": query, "p_limit": limit}
        ).execute()
        data = response.data
        if not isinstance(data, list):
            return []
        return [row for row in data if isinstance(row, dict)]
