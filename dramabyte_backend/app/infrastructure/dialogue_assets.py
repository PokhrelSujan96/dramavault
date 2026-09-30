import time
from pathlib import Path
from typing import Any

import fal_client

from app.core.config import settings
from app.infrastructure.adapters.fal import FalMediaProvider
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.dialogue_store import DialogueStore
from app.infrastructure.production_lock import ProductionLock
from app.infrastructure.provider_checkpoint import result_once, submit_once
from app.infrastructure.rendering import download


class DialogueAssets:
    def __init__(self, store: DialogueStore, lease: ProductionLock, root: Path) -> None:
        FalMediaProvider()
        self.store, self.lease, self.root = store, lease, root
        self.storage = R2Storage()

    def generate(
        self,
        name: str,
        endpoint: str,
        arguments: dict[str, Any],
        cents: int,
        image: bool = False,
    ) -> str:
        self.lease.ensure()
        if name in self.store.row["assets"]:
            return str(self.store.row["assets"][name])
        prior = self.store.row["requests"].get(name)
        stable = {key: value for key, value in arguments.items() if "url" not in key}
        entry = self.store.reserve(name, cents, [endpoint, stable])
        request_id = entry.get("request_id")
        if not request_id:
            if prior and prior.get("pending"):
                raise RuntimeError("Ambiguous paid submission; reconcile before retry")
            self.store.request(name, pending=True, endpoint=endpoint)
            handle = submit_once(
                lambda: fal_client.submit(endpoint, arguments=arguments),
                lambda: self.store.request(name, pending=False),
            )
            request_id = handle.request_id
            self.store.request(name, request_id=request_id)
        deadline = time.monotonic() + settings.hybrid_provider_timeout
        while not isinstance(
            fal_client.status(endpoint, request_id), fal_client.Completed
        ):
            self.lease.ensure()
            if time.monotonic() > deadline:
                raise TimeoutError("Provider pending; resume reuses saved request ID")
            time.sleep(2)
        result = result_once(
            lambda: fal_client.result(endpoint, request_id),
            lambda: self.store.request(name, pending=False),
        )
        url = result["images"][0]["url"] if image else result["video"]["url"]
        path = self.root / f"{name}.{'png' if image else 'mp4'}"
        download(str(url), path)
        key = f"pilots/{self.store.row['id']}/{name}/{request_id}{path.suffix}"
        self.storage.upload(path, key, "image/png" if image else "video/mp4")
        self.store.asset(name, key)
        self.store.request(name, pending=False)
        return key

    def local(self, name: str, path: Path, content_type: str) -> str:
        self.lease.ensure()
        existing = self.store.row["assets"].get(name)
        if existing:
            return str(existing)
        key = f"pilots/{self.store.row['id']}/{name}{path.suffix}"
        self.storage.upload(path, key, content_type)
        self.store.asset(name, key)
        return key

    def fetch(self, key: str, path: Path) -> None:
        download(self.storage.signed_url(key), path)
