from datetime import datetime

from pydantic import BaseModel


class CommentError(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


class Comment(BaseModel):
    id: str
    episode_id: str
    parent_id: str | None = None
    body: str
    created_at: datetime
    like_count: int = 0
    reply_count: int = 0
    liked: bool = False
    author_id: str
    author_name: str = "Deleted user"
    author_avatar: str | None = None
    is_mine: bool = False


class CommentPage(BaseModel):
    items: list[Comment]
    next_cursor: str | None


class LikeResult(BaseModel):
    like_count: int
