from uuid import UUID

from supabase import AsyncClient


class GuestViewRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def record(self, episode: UUID, event: UUID) -> str:
        result = await self.client.rpc(
            "record_guest_view",
            {
                "p_episode": str(episode),
                "p_event": str(event),
            },
        ).execute()
        return str(result.data)
