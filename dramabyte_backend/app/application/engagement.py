from typing import Protocol
from uuid import UUID

from app.domain.discover import DiscoverItem
from app.domain.engagement import EngagementError, EpisodeEngagement
from app.domain.ratings import average_rating


class EngagementStore(Protocol):
    async def stats(
        self, episode_ids: list[str], user_id: UUID
    ) -> dict[str, EpisodeEngagement]: ...

    async def record_views(
        self,
        user_id: UUID,
        batch_id: UUID,
        counts: dict[str, int],
        max_items: int,
        max_item_count: int,
        max_per_minute: int,
    ) -> str: ...


class EngagementService:
    def __init__(
        self,
        store: EngagementStore,
        max_items: int,
        max_item_count: int,
        max_per_minute: int,
    ) -> None:
        self.store = store
        self.max_items = max_items
        self.max_item_count = max_item_count
        self.max_per_minute = max_per_minute

    async def decorate(
        self, items: list[DiscoverItem], user_id: UUID
    ) -> list[DiscoverItem]:
        if not items:
            return items
        stats = await self.store.stats([item.episode_id for item in items], user_id)
        return [
            item.model_copy(
                update={
                    "views": s.views,
                    "likes": s.likes,
                    "liked": s.liked,
                    "comments": s.comments,
                    "rating_average": average_rating(s.rating_sum, s.rating_count),
                    "rating_count": s.rating_count,
                    "my_rating": s.my_rating,
                }
            )
            if (s := stats.get(item.episode_id))
            else item
            for item in items
        ]

    async def record_views(
        self, user_id: UUID, batch_id: UUID, counts: dict[UUID, int]
    ) -> None:
        cleaned: dict[str, int] = {}
        for episode_id, count in counts.items():
            if count > 0:
                key = str(episode_id)
                cleaned[key] = min(cleaned.get(key, 0) + count, self.max_item_count)
        if not cleaned or len(cleaned) > self.max_items:
            raise EngagementError("invalid")
        result = await self.store.record_views(
            user_id,
            batch_id,
            cleaned,
            self.max_items,
            self.max_item_count,
            self.max_per_minute,
        )
        if result not in ("ok", "duplicate"):
            raise EngagementError(result)
