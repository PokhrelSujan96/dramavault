from typing import Any
from uuid import uuid4

from postgrest.exceptions import APIError

from app.infrastructure.repositories.engagement import EngagementRepository


class Result:
    def __init__(self, data: list[dict[str, Any]]) -> None:
        self.data = data


class Query:
    def __init__(self, client: "Client", table: str) -> None:
        self.client, self.table, self.columns = client, table, ""

    def select(self, columns: str) -> "Query":
        self.columns = columns
        return self

    def eq(self, *args: Any) -> "Query":
        return self

    def in_(self, *args: Any) -> "Query":
        return self

    async def execute(self) -> Result:
        self.client.selects.append(self.columns)
        if self.table == "episode_stats":
            if "comments" in self.columns and not self.client.has_comments:
                raise APIError({"code": "42703", "message": "no column"})
            row = {"episode_id": "e1", "views": 5, "likes": 2}
            if "comments" in self.columns:
                row["comments"] = 9
            return Result([row])
        return Result([])


class Client:
    def __init__(self, has_comments: bool) -> None:
        self.has_comments = has_comments
        self.selects: list[str] = []

    def table(self, name: str) -> Query:
        return Query(self, name)


async def test_comment_counts_are_read_when_the_migration_is_applied() -> None:
    stats = await EngagementRepository(Client(True)).stats(["e1"], uuid4())  # type: ignore[arg-type]
    assert stats["e1"].comments == 9


async def test_discover_keeps_working_before_the_comments_migration() -> None:
    client = Client(False)
    stats = await EngagementRepository(client).stats(["e1"], uuid4())  # type: ignore[arg-type]
    assert (stats["e1"].views, stats["e1"].likes, stats["e1"].comments) == (5, 2, 0)
    assert "episode_id,views,likes" in client.selects
