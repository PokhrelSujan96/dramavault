from typing import Any
from uuid import uuid4

import pytest

from app.application.engagement import EngagementService
from app.domain.discover import DiscoverItem
from app.domain.engagement import EngagementError, EpisodeEngagement

USER = uuid4()


def item(episode_id: str) -> DiscoverItem:
    return DiscoverItem(
        series_id="s",
        episode_id=episode_id,
        title="T",
        description="",
        genre="G",
        thumbnail_url="",
        episode_number=1,
        duration_seconds=60,
        aspect_ratio="9:16",
        video_url="https://cdn/x",
        published_count=1,
        likes=99,
    )


class FakeStore:
    def __init__(self, result: str = "ok") -> None:
        self.result = result
        self.stats_calls: list[list[str]] = []
        self.recorded: list[dict[str, Any]] = []

    async def stats(self, episode_ids, user_id):
        self.stats_calls.append(episode_ids)
        return {"a": EpisodeEngagement(views=1200, likes=7, liked=True)}

    async def record_views(self, user_id, batch_id, counts, *limits):
        self.recorded.append({"batch": batch_id, "counts": counts, "limits": limits})
        return self.result


def service(store: FakeStore) -> EngagementService:
    return EngagementService(store, 50, 100, 120)


async def test_decorate_overlays_counts_and_liked_state() -> None:
    store = FakeStore()
    result = await service(store).decorate([item("a"), item("b")], USER)
    assert (result[0].views, result[0].likes, result[0].liked) == (1200, 7, True)
    assert (result[1].views, result[1].likes, result[1].liked) == (0, 99, False)
    assert store.stats_calls == [["a", "b"]]


async def test_decorate_skips_the_query_for_empty_pages() -> None:
    store = FakeStore()
    assert await service(store).decorate([], USER) == []
    assert store.stats_calls == []


async def test_views_are_coalesced_capped_and_sent_with_limits() -> None:
    store = FakeStore()
    episode = uuid4()
    await service(store).record_views(USER, uuid4(), {episode: 250, uuid4(): 0})
    sent = store.recorded[0]
    assert sent["counts"] == {str(episode): 100}
    assert sent["limits"] == (50, 100, 120)


@pytest.mark.parametrize("result", ["ok", "duplicate"])
async def test_success_and_duplicate_batches_are_both_fine(result: str) -> None:
    await service(FakeStore(result)).record_views(USER, uuid4(), {uuid4(): 3})


@pytest.mark.parametrize("code", ["rate_limited", "user_unavailable", "invalid"])
async def test_store_failures_are_raised(code: str) -> None:
    with pytest.raises(EngagementError) as caught:
        await service(FakeStore(code)).record_views(USER, uuid4(), {uuid4(): 3})
    assert caught.value.code == code


async def test_empty_or_oversized_batches_never_reach_the_store() -> None:
    store = FakeStore()
    svc = EngagementService(store, 2, 100, 120)
    for counts in ({}, {uuid4(): 0}, {uuid4(): 1, uuid4(): 1, uuid4(): 1}):
        with pytest.raises(EngagementError):
            await svc.record_views(USER, uuid4(), counts)
    assert store.recorded == []


