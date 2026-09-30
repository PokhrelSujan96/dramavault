import argparse
from pathlib import Path

from app.core.config import settings
from app.domain.dialogue import PilotPlan
from app.infrastructure.dialogue_assets import DialogueAssets
from app.infrastructure.dialogue_direction import keyframe_prompt
from app.infrastructure.dialogue_store import DialogueStore
from app.infrastructure.production_lock import ProductionLock
from supabase import create_client


def repair(pilot_id: str) -> None:
    if not settings.dialogue_paid_enabled:
        raise ValueError("Paid generation is disabled")
    database = create_client(settings.supabase_url, settings.supabase_service_role_key)
    store = DialogueStore(database, pilot_id)
    with ProductionLock(store.row["project_id"]) as lease:
        store = DialogueStore(database, pilot_id)
        if store.row["state"] not in {"review", "failed"}:
            raise ValueError("Only unrendered review pilots can be repaired")
        if any(name.startswith("motion-") for name in store.row["assets"]):
            raise ValueError("Motion already exists; create a new revision instead")
        plan = PilotPlan.model_validate(store.row["plan"])
        root = (Path("output/pilots") / pilot_id / "wardrobe-review").resolve()
        root.mkdir(parents=True, exist_ok=True)
        assets = DialogueAssets(store, lease, root)
        approvals = dict(store.row["approvals"])
        for shot in plan.shots:
            approvals[f"image-{shot.index}"] = False
            approvals[f"clip-{shot.index}"] = False
        store.save(approvals=approvals, state="review")
        for shot in plan.shots:
            people = [
                person
                for person in store.row["cast_snapshot"]
                if person["id"] in shot.character_ids
            ]
            refs = [
                *[person["reference_key"] for person in people],
                store.row["assets"]["location"],
            ]
            name = f"wardrobe-v2-{shot.index}"
            key = assets.generate(
                name,
                "fal-ai/flux-2/klein/9b/edit",
                {
                    "prompt": keyframe_prompt(plan, shot, store.row["cast_snapshot"]),
                    "image_urls": [assets.storage.signed_url(ref) for ref in refs],
                    "image_size": "portrait_16_9",
                    "num_images": 1,
                    "num_inference_steps": 4,
                    "seed": 48271 + shot.index,
                    "enable_safety_checker": True,
                    "output_format": "png",
                },
                10,
                image=True,
            )
            previous = store.row["assets"][f"image-{shot.index}"]
            if f"rejected-image-{shot.index}" not in store.row["assets"]:
                store.asset(f"rejected-image-{shot.index}", previous)
            store.asset(f"image-{shot.index}", key)
            path = root / f"{name}.png"
            if not path.exists():
                assets.fetch(key, path)
            print(f"Shot {shot.index + 1} replaced; review required", flush=True)
        store.project_state("review", "images", 40)
        print(f"Reserved allowance: ${store.row['reserved_cents'] / 100:.2f}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("pilot_id")
    repair(parser.parse_args().pilot_id)
