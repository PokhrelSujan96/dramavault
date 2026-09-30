from typing import Any
from uuid import UUID

from supabase import AsyncClient


class SeriesRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def details(self, series_id: UUID) -> dict[str, Any] | None:
        response = await self.client.rpc(
            "series_details", {"p_series": str(series_id)}
        ).execute()
        return response.data if isinstance(response.data, dict) else None

    async def playlist(self, series_id: UUID) -> list[dict[str, Any]]:
        response = await self.client.rpc(
            "series_playlist", {"p_series": str(series_id)}
        ).execute()
        data = response.data
        if not isinstance(data, list):
            return []
        return [row for row in data if isinstance(row, dict)]

    async def public_playlist(self, series_id: UUID) -> list[dict[str, Any]]:
        response = await self.client.rpc(
            "public_series_playlist", {"p_series": str(series_id)}
        ).execute()
        data = response.data
        return (
            [row for row in data if isinstance(row, dict)]
            if isinstance(data, list)
            else []
        )
