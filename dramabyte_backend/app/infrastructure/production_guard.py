from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import HTTPException
from redis.exceptions import RedisError
from starlette.concurrency import run_in_threadpool

from app.infrastructure.production_lock import ProductionLock


@asynccontextmanager
async def production_guard(project_id: str) -> AsyncIterator[None]:
    lease = ProductionLock(project_id)
    try:
        await run_in_threadpool(lease.__enter__)
    except RuntimeError as error:
        raise HTTPException(409, "This production is currently busy") from error
    except RedisError as error:
        raise HTTPException(
            503, "Redis is unavailable; production is paused safely"
        ) from error
    try:
        yield
        lease.ensure()
    finally:
        await run_in_threadpool(lease.__exit__, None, None, None)
