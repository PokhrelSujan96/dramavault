import hashlib
import time
from pathlib import Path
from typing import Any

import fal_client

from app.core.config import settings
from app.domain.hybrid import SceneSpec
from app.infrastructure.adapters.fal import FalMediaProvider
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.environment_assets import environment_id
from app.infrastructure.production_lock import ProductionLock
from app.infrastructure.production_store import ProductionStore
from app.infrastructure.provider_checkpoint import result_once, submit_once
from app.infrastructure.rendering import download
from app.infrastructure.scene_prompts import (
    camera_clause,
    motion_negative,
    scene_prompt,
)


class HybridAssets:
    def __init__(self, store: ProductionStore, lease: ProductionLock) -> None:
        self.store = store
        self.lease = lease
        self.storage = R2Storage()
        self.media = FalMediaProvider()

    def image(
        self, shot: dict[str, Any], run: dict[str, Any], aspect: str, root: Path
    ) -> str:
        return self._asset(shot, run, aspect, root, "image")

    def video(
        self, shot: dict[str, Any], run: dict[str, Any], aspect: str, root: Path
    ) -> str:
        return self._asset(shot, run, aspect, root, "video")

    def _asset(
        self,
        shot: dict[str, Any],
        run: dict[str, Any],
        aspect: str,
        root: Path,
        kind: str,
    ) -> str:
        self.lease.ensure()
        key_field = f"{kind}_key"
        if shot.get(key_field):
            return str(shot[key_field])
        endpoint, arguments = self._arguments(shot, run, aspect, kind)
        endpoint = str(shot.get(f"{kind}_model") or endpoint)
        request_field = f"{kind}_request_id"
        pending_field = f"{kind}_pending"
        request_id = shot.get(request_field)
        if not request_id:
            if shot.get(pending_field):
                raise RuntimeError(
                    "Ambiguous paid submission; reconcile in Fal before retry"
                )
            self.store.update(
                "production_shots",
                shot["id"],
                {
                    pending_field: True,
                    f"{kind}_model": endpoint,
                },
            )
            handle = submit_once(
                lambda: fal_client.submit(endpoint, arguments=arguments),
                lambda: self.store.update(
                    "production_shots", shot["id"], {pending_field: False}
                ),
            )
            request_id = handle.request_id
            self.store.update(
                "production_shots", shot["id"], {request_field: request_id}
            )
        deadline = time.monotonic() + settings.hybrid_provider_timeout
        while True:
            self.lease.ensure()
            status = fal_client.status(endpoint, str(request_id), with_logs=False)
            if isinstance(status, fal_client.Completed):
                break
            if time.monotonic() >= deadline:
                raise TimeoutError(
                    "Fal request is still pending; resume reuses its request ID"
                )
            time.sleep(2)
        result = result_once(
            lambda: fal_client.result(endpoint, str(request_id)),
            lambda: self.store.update(
                "production_shots", shot["id"], {pending_field: False}
            ),
        )
        url = result["video"]["url"] if kind == "video" else result["images"][0]["url"]
        extension = "mp4" if kind == "video" else "png"
        path = root / f"asset-{shot['shot_index']}.{extension}"
        download(str(url), path)
        key = f"hybrid/{run['id']}/{shot['id']}/{request_id}/{kind}.{extension}"
        self.storage.upload(path, key, "video/mp4" if kind == "video" else "image/png")
        self.store.update(
            "production_shots",
            shot["id"],
            {
                key_field: key,
                pending_field: False,
            },
        )
        return key

    def _arguments(
        self, shot: dict[str, Any], run: dict[str, Any], aspect: str, kind: str
    ) -> tuple[str, dict[str, Any]]:
        prompt = scene_prompt(shot)
        identity = f"{shot['id']}:{shot.get('image_attempt', 0)}"
        seed = int(hashlib.sha256(identity.encode()).hexdigest()[:8], 16)
        if kind == "video":
            return "fal-ai/wan-i2v", {
                "prompt": prompt
                + camera_clause(SceneSpec.model_validate(shot["scene_spec"]))
                + " Background people keep moving naturally throughout."
                + " One continuous take: perform only the stated action. "
                "Preserve location, facial identity, wardrobe and object ownership.",
                "negative_prompt": motion_negative(shot),
                "enable_prompt_expansion": False,
                "image_url": self.storage.signed_url(str(shot["image_key"])),
                "aspect_ratio": aspect,
                "resolution": "480p",
                "num_frames": 81,
                "frames_per_second": 16,
                "seed": seed,
                "enable_safety_checker": True,
            }
        cast = [
            row for row in run["cast_snapshot"] if row["id"] in shot["character_ids"]
        ]
        arguments: dict[str, Any] = {
            "prompt": prompt,
            "seed": seed,
            "num_images": 1,
            "image_size": self.media._image_size(aspect),
            "num_inference_steps": 4,
            "enable_safety_checker": True,
            "output_format": "png",
        }
        environment = run.get("environment_assets", {}).get(
            environment_id(str(shot["scene_spec"]["location"]))
        )
        if environment and len(cast) > 3:
            raise ValueError(
                "Use at most three named characters plus the shared set per shot"
            )
        if cast or environment:
            identities = "; ".join(
                f"Reference {index + 1}: {row['name']}, {row['description']}"
                for index, row in enumerate(cast)
            )
            arguments["prompt"] = (
                f"{identities}. Use references ONLY for identity, hair and wardrobe. "
                "Show each named character exactly once. Never duplicate a face "
                "or place a named character's clone among background extras. "
                "Discard their backgrounds, weather, lighting and poses. "
                "Do not import props unless the scene explicitly requires them. "
                f"Render the scene specification exactly: {prompt}"
            )
            arguments["image_urls"] = [
                self.storage.signed_url(row["reference_key"]) for row in cast
            ]
            if environment:
                arguments["image_urls"].append(self.storage.signed_url(environment))
                arguments["prompt"] += (
                    f" Reference {len(cast) + 1} is the EMPTY location plate. "
                    "Reuse its exact architecture and daylight, not its camera angle. "
                    "Add only the background extras explicitly required by the scene. "
                    "Do not invent a new room or blend faces and outfits "
                    "between references."
                )
            return settings.hybrid_reference_model, arguments
        arguments["prompt"] = prompt
        return "fal-ai/flux/schnell", arguments
