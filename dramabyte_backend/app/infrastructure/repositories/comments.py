from datetime import datetime
from typing import Any
from uuid import UUID

from supabase import AsyncClient


def _rows(data: Any) -> list[dict[str, Any]]:
    return (
        [row for row in data if isinstance(row, dict)] if isinstance(data, list) else []
    )


class CommentRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def list_new(
        self,
        viewer: UUID,
        episode: UUID,
        after: tuple[datetime, UUID] | None,
        limit: int,
    ) -> list[dict[str, Any]]:
        response = await self.client.rpc(
            "list_comments_new",
            {
                "p_viewer": str(viewer),
                "p_episode": str(episode),
                "p_after_created": after[0].isoformat() if after else None,
                "p_after_id": str(after[1]) if after else None,
                "p_limit": limit,
            },
        ).execute()
        return _rows(response.data)

    async def list_top(
        self,
        viewer: UUID,
        episode: UUID,
        after: tuple[int, datetime, UUID] | None,
        limit: int,
    ) -> list[dict[str, Any]]:
        response = await self.client.rpc(
            "list_comments_top",
            {
                "p_viewer": str(viewer),
                "p_episode": str(episode),
                "p_after_likes": after[0] if after else None,
                "p_after_created": after[1].isoformat() if after else None,
                "p_after_id": str(after[2]) if after else None,
                "p_limit": limit,
            },
        ).execute()
        return _rows(response.data)

    async def list_replies(
        self,
        viewer: UUID,
        parent: UUID,
        after: tuple[datetime, UUID] | None,
        limit: int,
    ) -> list[dict[str, Any]]:
        response = await self.client.rpc(
            "list_comment_replies",
            {
                "p_viewer": str(viewer),
                "p_parent": str(parent),
                "p_after_created": after[0].isoformat() if after else None,
                "p_after_id": str(after[1]) if after else None,
                "p_limit": limit,
            },
        ).execute()
        return _rows(response.data)

    async def by_ids(self, viewer: UUID, ids: list[UUID]) -> list[dict[str, Any]]:
        response = await self.client.rpc(
            "comments_by_ids",
            {"p_viewer": str(viewer), "p_ids": [str(i) for i in ids]},
        ).execute()
        return _rows(response.data)

    async def post(
        self,
        user: UUID,
        episode: UUID,
        parent: UUID | None,
        body: str,
        key: UUID | None,
        max_per_minute: int,
        max_length: int,
    ) -> dict[str, Any]:
        response = await self.client.rpc(
            "post_comment",
            {
                "p_user": str(user),
                "p_episode": str(episode),
                "p_parent": str(parent) if parent else None,
                "p_body": body,
                "p_key": str(key) if key else None,
                "p_max_per_minute": max_per_minute,
                "p_max_length": max_length,
            },
        ).execute()
        return response.data if isinstance(response.data, dict) else {}

    async def toggle_like(
        self, user: UUID, comment: UUID, liked: bool
    ) -> dict[str, Any]:
        response = await self.client.rpc(
            "toggle_comment_like",
            {"p_user": str(user), "p_comment": str(comment), "p_liked": liked},
        ).execute()
        return response.data if isinstance(response.data, dict) else {}

    async def delete(self, user: UUID, comment: UUID) -> str:
        response = await self.client.rpc(
            "delete_comment", {"p_user": str(user), "p_comment": str(comment)}
        ).execute()
        return str(response.data)

    async def report(self, user: UUID, comment: UUID, reason: str) -> str:
        response = await self.client.rpc(
            "report_comment",
            {"p_user": str(user), "p_comment": str(comment), "p_reason": reason},
        ).execute()
        return str(response.data)
