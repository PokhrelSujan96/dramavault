from pydantic import BaseModel


class RatingError(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


class RatingSummary(BaseModel):
    average: float | None = None
    count: int = 0
    my_rating: int | None = None


def average_rating(total: int, count: int) -> float | None:
    return round(total / count, 1) if count > 0 else None
