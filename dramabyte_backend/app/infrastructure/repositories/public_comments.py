from uuid import UUID

from supabase import AsyncClient


class PublicCommentAccess:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def published(self, episode: UUID) -> bool:
        result = (
            await self.client.table("episodes")
            .select("id,projects!inner(status)")
            .eq("id", str(episode))
            .eq("projects.status", "published")
            .limit(1)
            .execute()
        )
        return bool(result.data)

    async def parent_episode(self, parent: UUID) -> UUID | None:
        result = (
            await self.client.table("episode_comments")
            .select("episode_id")
            .eq("id", str(parent))
            .eq("is_hidden", False)
            .limit(1)
            .execute()
        )
        return UUID(str(result.data[0]["episode_id"])) if result.data else None
