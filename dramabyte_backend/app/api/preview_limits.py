import hashlib
import time

from fastapi import HTTPException, Request
from redis.asyncio import Redis
from redis.exceptions import RedisError

from app.core.config import settings

_SCRIPT = """
local n = redis.call('INCR', KEYS[1])
if n == 1 then redis.call('EXPIRE', KEYS[1], 65) end
return n
"""


async def limit_preview(request: Request) -> None:
    address = request.client.host if request.client else "unknown"
    digest = hashlib.sha256(address.encode()).hexdigest()
    key = f"preview:{digest}:{int(time.time()) // 60}"
    try:
        async with Redis.from_url(
            settings.redis_url,
            socket_connect_timeout=2,
            socket_timeout=2,
        ) as client:
            count = await client.eval(_SCRIPT, 1, key)
    except RedisError as error:
        raise HTTPException(
            status_code=503, detail="Playback temporarily unavailable"
        ) from error
    if int(count) > 120:
        raise HTTPException(
            status_code=429,
            detail="Too many preview requests",
            headers={"Retry-After": "60"},
        )
