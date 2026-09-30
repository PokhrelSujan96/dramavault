from datetime import datetime
from typing import Any
from uuid import UUID

from supabase import AsyncClient


class DiscoverRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def rows(
        self, after: tuple[datetime, UUID] | None, limit: int
    ) -> list[dict[str, Any]]:
        response = await self.client.rpc(
            "discover_feed",
            {
                "p_after_created": after[0].isoformat() if after else None,
                "p_after_id": str(after[1]) if after else None,
                "p_limit": limit,
            },
        ).execute()
        data = response.data
        if not isinstance(data, list):
            return []
        return [row for row in data if isinstance(row, dict)]
