from pydantic import BaseModel


class EngagementError(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


class EpisodeEngagement(BaseModel):
    views: int = 0
    likes: int = 0
    liked: bool = False
    comments: int = 0
    rating_sum: int = 0
    rating_count: int = 0
    my_rating: int | None = None
