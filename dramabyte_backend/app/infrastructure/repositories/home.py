from typing import Any

from supabase import AsyncClient


class HomeRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def feed(self, limit: int) -> dict[str, Any]:
        response = await self.client.rpc("home_feed", {"p_limit": limit}).execute()
        return response.data if isinstance(response.data, dict) else {}
