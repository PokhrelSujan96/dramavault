import hashlib
import time
from functools import partial
from pathlib import Path
from typing import Any

import fal_client

from app.core.config import settings
from app.infrastructure.adapters.fal import FalMediaProvider
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.production_lock import ProductionLock
from app.infrastructure.production_store import ProductionStore
from app.infrastructure.provider_checkpoint import result_once, submit_once
from app.infrastructure.rendering import download


def environment_id(location: str) -> str:
    return hashlib.sha256(" ".join(location.lower().split()).encode()).hexdigest()[:20]


class EnvironmentAssets:
    def __init__(self, store: ProductionStore, lease: ProductionLock) -> None:
        self.store, self.lease = store, lease
        self.storage = R2Storage()
        FalMediaProvider()

    def prepare(
        self, run: dict[str, Any], shots: list[dict[str, Any]], root: Path
    ) -> None:
        keys = dict(run.get("environment_assets", {}))
        requests = dict(run.get("environment_requests", {}))
        for shot in shots:
            location = str(shot["scene_spec"]["location"])
            identifier = environment_id(location)
            if identifier in keys:
                continue
            self.lease.ensure()
            entry = dict(requests.get(identifier, {}))
            requests[identifier] = entry
            endpoint = "fal-ai/flux/schnell"

            def rejected(saved_entry: dict[str, Any] = entry) -> None:
                saved_entry["pending"] = False
                self.store.update(
                    "production_runs", run["id"], {"environment_requests": requests}
                )

            if not entry.get("request_id"):
                if entry.get("pending"):
                    raise RuntimeError(
                        "Ambiguous environment request; reconcile before retry"
                    )
                entry["pending"] = True
                requests[identifier] = entry
                self.store.update(
                    "production_runs", run["id"], {"environment_requests": requests}
                )

                handle = submit_once(
                    partial(
                        fal_client.submit,
                        endpoint,
                        arguments={
                            "prompt": f"Cinematic EMPTY location plate: {location}. "
                            "No people, faces, silhouettes, text or human reflections. "
                            "Clearly establish doors, windows, furniture and lighting.",
                            "image_size": "portrait_16_9",
                            "num_images": 1,
                            "num_inference_steps": 4,
                            "enable_safety_checker": True,
                        },
                    ),
                    rejected,
                )
                entry["request_id"] = handle.request_id
                self.store.update(
                    "production_runs", run["id"], {"environment_requests": requests}
                )
            deadline = time.monotonic() + settings.hybrid_provider_timeout
            while not isinstance(
                fal_client.status(endpoint, entry["request_id"]), fal_client.Completed
            ):
                self.lease.ensure()
                if time.monotonic() > deadline:
                    raise TimeoutError(
                        "Environment pending; resume reuses its request ID"
                    )
                time.sleep(2)
            result = result_once(
                partial(fal_client.result, endpoint, entry["request_id"]),
                rejected,
            )
            self.lease.ensure()
            path = root / f"set-{identifier}.png"
            download(str(result["images"][0]["url"]), path)
            self.lease.ensure()
            key = f"hybrid/{run['id']}/sets/{identifier}/{entry['request_id']}.png"
            self.storage.upload(path, key, "image/png")
            keys[identifier] = key
            entry["pending"] = False
            self.store.update(
                "production_runs",
                run["id"],
                {
                    "environment_assets": keys,
                    "environment_requests": requests,
                },
            )
        run["environment_assets"] = keys
