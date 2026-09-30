from threading import Event, Thread
from types import TracebackType
from uuid import uuid4

from redis import Redis

from app.core.config import settings


class ProductionLock:
    def __init__(self, project_id: str) -> None:
        self.client = Redis.from_url(settings.redis_url)
        self.key = f"production-lock:{project_id}"
        self.token = str(uuid4())
        self.stop = Event()
        self.lost = Event()
        self.thread = Thread(target=self._renew, daemon=True)

    def __enter__(self) -> "ProductionLock":
        if not self.client.set(self.key, self.token, nx=True, ex=120):
            raise RuntimeError("Production is already running for this project")
        self.thread.start()
        return self

    def ensure(self) -> None:
        if self.lost.is_set():
            raise RuntimeError("Production lease was lost; paid calls stopped")

    def _renew(self) -> None:
        while not self.stop.wait(30):
            try:
                refreshed = self.client.eval(
                    "if redis.call('get',KEYS[1]) == ARGV[1] then "
                    "return redis.call('expire',KEYS[1],120) else return 0 end",
                    1,
                    self.key,
                    self.token,
                )
                if not refreshed:
                    self.lost.set()
                    return
            except Exception:
                self.lost.set()
                return

    def __exit__(
        self,
        kind: type[BaseException] | None,
        value: BaseException | None,
        traceback: TracebackType | None,
    ) -> None:
        self.stop.set()
        self.thread.join(timeout=5)
        try:
            self.client.eval(
                "if redis.call('get',KEYS[1]) == ARGV[1] then "
                "return redis.call('del',KEYS[1]) else return 0 end",
                1,
                self.key,
                self.token,
            )
        finally:
            self.client.close()
