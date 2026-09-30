import asyncio
from typing import Any
from uuid import UUID

from postgrest.exceptions import APIError

from app.domain.engagement import EpisodeEngagement
from supabase import AsyncClient


class EngagementRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    _COLUMN_SETS = (
        "episode_id,views,likes,comments,rating_sum,rating_count",
        "episode_id,views,likes,comments",
        "episode_id,views,likes",
    )

    async def _counts(self, episode_ids: list[str]) -> Any:
        for columns in self._COLUMN_SETS:
            try:
                return await (
                    self.client.table("episode_stats")
                    .select(columns)
                    .in_("episode_id", episode_ids)
                    .execute()
                )
            except APIError as error:
                if error.code != "42703" or columns == self._COLUMN_SETS[-1]:
                    raise

    async def _my_ratings(
        self, episode_ids: list[str], user_id: UUID
    ) -> dict[str, int]:
        try:
            response = await (
                self.client.table("episode_ratings")
                .select("episode_id,rating")
                .eq("user_id", str(user_id))
                .in_("episode_id", episode_ids)
                .execute()
            )
        except APIError as error:
            if error.code in {"42P01", "PGRST205"}:
                return {}
            raise
        return {
            str(row["episode_id"]): int(row["rating"])
            for row in response.data
            if isinstance(row, dict)
        }

    async def stats(
        self, episode_ids: list[str], user_id: UUID
    ) -> dict[str, EpisodeEngagement]:
        counts, liked, mine = await asyncio.gather(
            self._counts(episode_ids),
            self.client.table("episode_likes")
            .select("episode_id")
            .eq("user_id", str(user_id))
            .in_("episode_id", episode_ids)
            .execute(),
            self._my_ratings(episode_ids, user_id),
        )
        liked_ids = {
            str(row["episode_id"]) for row in liked.data if isinstance(row, dict)
        }
        result: dict[str, EpisodeEngagement] = {}
        for row in counts.data:
            if isinstance(row, dict):
                episode_id = str(row["episode_id"])
                result[episode_id] = EpisodeEngagement(
                    views=int(row["views"]),
                    likes=int(row["likes"]),
                    comments=int(row.get("comments", 0)),
                    rating_sum=int(row.get("rating_sum", 0)),
                    rating_count=int(row.get("rating_count", 0)),
                    my_rating=mine.get(episode_id),
                    liked=episode_id in liked_ids,
                )
        for episode_id in (liked_ids | mine.keys()) - result.keys():
            result[episode_id] = EpisodeEngagement(
                liked=episode_id in liked_ids, my_rating=mine.get(episode_id)
            )
        return result

    async def record_views(
        self,
        user_id: UUID,
        batch_id: UUID,
        counts: dict[str, int],
        max_items: int,
        max_item_count: int,
        max_per_minute: int,
    ) -> str:
        items: list[dict[str, Any]] = [
            {"episode_id": episode_id, "count": count}
            for episode_id, count in counts.items()
        ]
        response = await self.client.rpc(
            "record_views",
            {
                "p_user": str(user_id),
                "p_batch": str(batch_id),
                "p_items": items,
                "p_max_items": max_items,
                "p_max_item_count": max_item_count,
                "p_max_per_minute": max_per_minute,
            },
        ).execute()
        return str(response.data)
