import argparse
from pathlib import Path
from typing import Any
from uuid import uuid4

from app.application.dialogue_production import DialogueProduction
from app.core.config import settings
from app.domain.school_characters import CAST
from app.domain.school_pilot import school_pilot
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.dialogue_assets import DialogueAssets
from app.infrastructure.dialogue_store import DialogueStore
from app.infrastructure.production_lock import ProductionLock
from app.infrastructure.reference_images import normalize_reference
from supabase import create_client

TITLE = "After the Bell"
DESCRIPTION = (
    "A scholarship student discovers that belonging is not something the "
    "popular crowd gets to grant. An original school drama about bullying, "
    "courage and the cost of staying silent."
)


def prepare() -> str:
    database: Any = create_client(
        settings.supabase_url, settings.supabase_service_role_key
    )
    existing = database.table("series").select("id").eq("title", TITLE).execute().data
    if existing:
        series_id = existing[0]["id"]
        pilots = (
            database.table("dialogue_pilots")
            .select("id")
            .eq("series_id", series_id)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
            .data
        )
        if pilots:
            return str(pilots[0]["id"])
    else:
        series_id = str(uuid4())
        database.table("series").insert(
            {
                "id": series_id,
                "title": TITLE,
                "description": DESCRIPTION,
                "genre": "School drama",
                "target_episode_count": 15,
                "target_episode_seconds": 60,
            }
        ).execute()
    owners = (
        database.table("projects")
        .select("owner_id")
        .eq("id", "3f458c2b-42d8-4b4c-b67f-aaca3de8bc3a")
        .execute()
        .data
    )
    if not owners:
        raise ValueError("Existing owner not found; choose an authenticated admin")
    people = []
    for name, voice, description in CAST:
        rows = (
            database.table("series_characters")
            .select("*")
            .eq("series_id", series_id)
            .eq("name", name)
            .execute()
            .data
        )
        if rows:
            person = dict(rows[0])
        else:
            identifier = str(uuid4())
            person = (
                database.table("series_characters")
                .insert(
                    {
                        "id": identifier,
                        "series_id": series_id,
                        "name": name,
                        "description": description,
                        "reference_key": f"characters/{series_id}/{identifier}.png",
                    }
                )
                .execute()
                .data[0]
            )
        people.append({**person, "voice_reference": voice})
    plan = school_pilot(people[0]["id"], people[1]["id"])
    result = (
        database.rpc(
            "create_dialogue_pilot",
            {
                "p_owner_id": owners[0]["owner_id"],
                "p_series_id": series_id,
                "p_plan": plan.model_dump(mode="json"),
                "p_cast": people,
                "p_budget_cents": 500,
            },
        )
        .execute()
        .data
    )
    database.table("projects").update(
        {
            "title": "Episode 1 · The Empty Seat",
            "premise": DESCRIPTION,
            "script": "\n".join(shot.text for shot in plan.shots if shot.text),
        }
    ).eq("id", result["project_id"]).execute()
    database.table("episodes").insert(
        {
            "series_id": series_id,
            "project_id": result["project_id"],
            "episode_number": 1,
            "title": "The Empty Seat",
            "description": "Nia faces cafeteria bullying and refuses to back down.",
            "duration_seconds": 26,
        }
    ).execute()
    print(
        f"series={series_id} project={result['project_id']} pilot={result['id']}",
        flush=True,
    )
    return str(result["id"])


def portraits(pilot_id: str) -> None:
    if not settings.dialogue_paid_enabled:
        raise ValueError("Paid production is disabled")
    database = create_client(settings.supabase_url, settings.supabase_service_role_key)
    store = DialogueStore(database, pilot_id)
    root = (Path("output/pilots") / pilot_id / "references").resolve()
    root.mkdir(parents=True, exist_ok=True)
    with ProductionLock(store.row["project_id"]) as lease:
        assets = DialogueAssets(store, lease, root)
        for index, person in enumerate(store.row["cast_snapshot"]):
            name = f"portrait-{index}"
            key = assets.generate(
                name,
                "fal-ai/flux/schnell",
                {
                    "prompt": (
                        "Photorealistic character continuity reference portrait. "
                        f"{person['description']} Neutral grey studio background, "
                        "soft even daylight, front-facing chest-up portrait, natural "
                        "skin texture, neutral expression, unobstructed face. "
                        "Single fictional person, no text, no scene props."
                    ),
                    "image_size": "portrait_4_3",
                    "num_images": 1,
                    "num_inference_steps": 4,
                    "enable_safety_checker": True,
                },
                10,
                image=True,
            )
            source, normalized = root / f"{name}.png", root / f"{name}-normalized.png"
            assets.fetch(key, source)
            normalize_reference(source, normalized)
            R2Storage().upload(normalized, person["reference_key"], "image/png")
            print(f"portrait_ready={person['name']}", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("phase", choices=["prepare", "portraits", "run"])
    parser.add_argument("--pilot-id")
    args = parser.parse_args()
    if args.phase == "prepare":
        print("pilot_id=" + prepare(), flush=True)
        return
    if not args.pilot_id:
        raise ValueError("Provide --pilot-id")
    if args.phase == "portraits":
        portraits(args.pilot_id)
    else:
        database = create_client(
            settings.supabase_url, settings.supabase_service_role_key
        )
        print("state=" + DialogueProduction(database).run(args.pilot_id), flush=True)


if __name__ == "__main__":
    main()
