from typing import Any
from uuid import UUID

from postgrest.exceptions import APIError

from app.application.ratings import Kind
from supabase import AsyncClient

_MISSING = {"42P01", "42703", "PGRST205", "PGRST204"}


class RatingRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def rate(
        self, kind: Kind, user: UUID, target: UUID, rating: int, max_per_minute: int
    ) -> dict[str, Any]:
        response = await self.client.rpc(
            "rate_item",
            {
                "p_user": str(user),
                "p_kind": kind,
                "p_target": str(target),
                "p_rating": rating,
                "p_max_per_minute": max_per_minute,
            },
        ).execute()
        return response.data if isinstance(response.data, dict) else {}

    async def clear(self, kind: Kind, user: UUID, target: UUID) -> dict[str, Any]:
        response = await self.client.rpc(
            "clear_rating",
            {"p_user": str(user), "p_kind": kind, "p_target": str(target)},
        ).execute()
        return response.data if isinstance(response.data, dict) else {}

    async def series_totals(self, ids: list[str]) -> dict[str, tuple[int, int]]:
        try:
            response = await (
                self.client.table("series_rating_stats")
                .select("series_id,rating_sum,rating_count")
                .in_("series_id", ids)
                .execute()
            )
        except APIError as error:
            if error.code in _MISSING:
                return {}
            raise
        return {
            str(row["series_id"]): (int(row["rating_sum"]), int(row["rating_count"]))
            for row in response.data
            if isinstance(row, dict)
        }

    async def series_mine(self, user: UUID, series: UUID) -> int | None:
        try:
            response = await (
                self.client.table("series_ratings")
                .select("rating")
                .eq("user_id", str(user))
                .eq("series_id", str(series))
                .maybe_single()
                .execute()
            )
        except APIError as error:
            if error.code in _MISSING:
                return None
            raise
        data = response.data if response is not None else None
        return int(data["rating"]) if isinstance(data, dict) else None
