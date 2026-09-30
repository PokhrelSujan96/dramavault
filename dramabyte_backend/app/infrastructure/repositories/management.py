from typing import Any, cast

from fastapi import HTTPException
from postgrest.types import CountMethod

from supabase import AsyncClient


class ManagementRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def list(self, table: str, page: int, size: int) -> dict[str, Any]:
        result = (
            await self.client.table(table)
            .select("*", count=CountMethod.exact)
            .order("created_at", desc=True)
            .range((page - 1) * size, page * size - 1)
            .execute()
        )
        return {"items": result.data, "total": result.count, "page": page}

    async def get(self, table: str, identifier: str) -> dict[str, Any]:
        result = (
            await self.client.table(table)
            .select("*")
            .eq("id", identifier)
            .limit(1)
            .execute()
        )
        if not result.data:
            raise HTTPException(404, "Record not found")
        return dict(cast(dict[str, Any], result.data[0]))

    async def update(
        self, table: str, identifier: str, values: dict[str, Any]
    ) -> dict[str, Any]:
        await self.get(table, identifier)
        result = (
            await self.client.table(table).update(values).eq("id", identifier).execute()
        )
        return dict(cast(dict[str, Any], result.data[0]))

    async def create(self, table: str, values: dict[str, Any]) -> dict[str, Any]:
        result = await self.client.table(table).insert(values).execute()
        return dict(cast(dict[str, Any], result.data[0]))

    async def delete(self, table: str, identifier: str) -> None:
        await self.get(table, identifier)
        await self.client.table(table).delete().eq("id", identifier).execute()
