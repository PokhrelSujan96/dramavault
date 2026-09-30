import argparse
import json
import time
from functools import partial
from pathlib import Path
from typing import Any
from uuid import uuid4

import fal_client

from app.core.config import settings
from app.domain.last_seat_story import CAST
from app.infrastructure.adapters.fal import FalMediaProvider
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.production_lock import ProductionLock
from app.infrastructure.provider_checkpoint import result_once, submit_once
from app.infrastructure.reference_images import normalize_reference
from app.infrastructure.rendering import download
from supabase import create_client


def prepare_references(project_id: str) -> None:
    database: Any = create_client(
        settings.supabase_url, settings.supabase_service_role_key
    )
    project = (
        database.table("projects")
        .select("status,production_mode")
        .eq("id", project_id)
        .single()
        .execute()
        .data
    )
    if project["status"] != "draft" or project["production_mode"] != "narrated":
        raise ValueError("Only an unstarted narrated draft can receive demo references")
    episode = (
        database.table("episodes")
        .select("series_id")
        .eq("project_id", project_id)
        .single()
        .execute()
        .data
    )
    series_id = episode["series_id"]
    title = (
        database.table("series")
        .select("title")
        .eq("id", series_id)
        .single()
        .execute()
        .data
    )
    if title["title"] != "The Last Seat":
        raise ValueError("This reference setup is only for The Last Seat")
    root = (Path("output/demo-references") / series_id).resolve()
    root.mkdir(parents=True, exist_ok=True)
    FalMediaProvider()
    storage = R2Storage()
    with ProductionLock(project_id) as lease:
        for index, (name, description) in enumerate(CAST):
            existing = (
                database.table("series_characters")
                .select("id")
                .eq("series_id", series_id)
                .eq("name", name)
                .execute()
                .data
            )
            if existing:
                print(f"Reusing existing reference: {name}", flush=True)
                continue
            checkpoint = root / f"reference-{index}.json"
            entry: dict[str, Any] = (
                json.loads(checkpoint.read_text())
                if checkpoint.exists()
                else {"id": str(uuid4()), "pending": False}
            )

            def save(saved: dict[str, Any] = entry, path: Path = checkpoint) -> None:
                path.write_text(json.dumps(saved))

            def rejected(
                saved: dict[str, Any] = entry, path: Path = checkpoint
            ) -> None:
                saved["pending"] = False
                path.write_text(json.dumps(saved))

            endpoint = "fal-ai/flux/schnell"
            if not entry.get("request_id"):
                if entry["pending"]:
                    raise RuntimeError(
                        "Ambiguous portrait submission; reconcile before retry"
                    )
                lease.ensure()
                entry["pending"] = True
                save()
                arguments = {
                    "prompt": (
                        f"Photorealistic continuity reference: {description} "
                        "Single fictional person, frontal view, neutral expression. "
                        "Three-quarter body portrait down to knees, clear unobstructed "
                        "face and uniform. Neutral grey studio background, soft even "
                        "daylight, natural skin, no text, logos or additional people."
                    ),
                    "image_size": "portrait_4_3",
                    "num_images": 1,
                    "num_inference_steps": 4,
                    "enable_safety_checker": True,
                    "seed": 94100 + index,
                }
                handle = submit_once(
                    partial(fal_client.submit, endpoint, arguments=arguments), rejected
                )
                entry["request_id"] = handle.request_id
                save()
            deadline = time.monotonic() + settings.hybrid_provider_timeout
            while not isinstance(
                fal_client.status(endpoint, entry["request_id"]), fal_client.Completed
            ):
                lease.ensure()
                if time.monotonic() > deadline:
                    raise TimeoutError(
                        "Portrait pending; retry reuses the saved request"
                    )
                time.sleep(2)
            result = result_once(
                partial(fal_client.result, endpoint, entry["request_id"]), rejected
            )
            source, portrait = (
                root / f"reference-{index}.png",
                root / f"portrait-{index}.png",
            )
            download(str(result["images"][0]["url"]), source)
            normalize_reference(source, portrait)
            lease.ensure()
            key = f"characters/{series_id}/{entry['id']}.png"
            storage.upload(portrait, key, "image/png")
            database.table("series_characters").insert(
                {
                    "id": entry["id"],
                    "series_id": series_id,
                    "name": name,
                    "description": description,
                    "reference_key": key,
                }
            ).execute()
            entry["pending"] = False
            save()
            print(f"Reference ready: {name}", flush=True)
    print("All four references attached. Audio/video production has NOT started.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("project_id")
    parser.add_argument("--paid-confirmed", action="store_true")
    arguments = parser.parse_args()
    if not arguments.paid_confirmed:
        parser.error("Explicit --paid-confirmed is required for four portrait requests")
    prepare_references(arguments.project_id)
