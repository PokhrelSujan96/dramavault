from pathlib import Path
from shutil import copyfile
from typing import Any

from app.domain.caption_defaults import CAPTION_STYLE
from app.domain.dialogue import PilotPlan
from app.domain.narration_timing import TimedWord, aligned_captions
from app.infrastructure.dialogue_assets import DialogueAssets
from app.infrastructure.dialogue_audio import mix_dialogue
from app.infrastructure.hybrid_rendering import (
    assemble,
    frame_duration,
    render_shot,
    validate_master,
)
from app.infrastructure.production_store import ProductionStore
from app.infrastructure.rendering import create_ass
from app.infrastructure.video_export import render_export
from app.infrastructure.voice_validation import validate_voice


def finish_pilot(plan: PilotPlan, assets: DialogueAssets, root: Path) -> str:
    rendered: list[Path] = []
    captions: list[dict[str, Any]] = []
    start = 0.0
    for shot in plan.shots:
        assets.lease.ensure()
        name = (
            f"lipsync-{shot.index}"
            if shot.role == "dialogue"
            else f"motion-{shot.index}"
        )
        source, output = (
            root / f"source-{shot.index}.mp4",
            root / f"shot-{shot.index}.mp4",
        )
        assets.fetch(assets.store.row["assets"][name], source)
        end = start + shot.seconds
        render_shot(source, output, frame_duration(start, end), "motion", "9:16")
        rendered.append(output)
        words = [TimedWord.model_validate(word) for word in shot.words]
        for caption in aligned_captions(words):
            captions.append(
                {
                    **caption,
                    "id": len(captions),
                    "start": round(start + float(str(caption["start"])), 3),
                    "end": round(start + float(str(caption["end"])), 3),
                }
            )
        start = end
    audio = mix_dialogue(plan, assets, root)
    validate_voice(audio)
    final = root / "pilot.mp4"
    assemble(rendered, audio, final, start)
    validate_master(final, start, "9:16")
    artifact = Path("output/pilots") / assets.store.row["id"]
    artifact = artifact.resolve()
    artifact.mkdir(parents=True, exist_ok=True)
    copyfile(final, artifact / "master.mp4")
    create_ass(captions, CAPTION_STYLE, artifact / "captions.ass")
    render_export(
        artifact / "master.mp4", artifact / "captions.ass", artifact / "preview.mp4"
    )
    key = assets.local("master", final, "video/mp4")
    store = ProductionStore(assets.store.database)
    project_id = assets.store.row["project_id"]
    assets.store.database.table("episodes").update(
        {"duration_seconds": round(start)}
    ).eq("project_id", project_id).execute()
    store.job(
        project_id,
        "subtitles",
        "dramabyte-editor",
        {"captions": captions, "style": CAPTION_STYLE},
    )
    store.job(
        project_id,
        "publish",
        "cloudflare-r2-preview",
        {"key": key, "pilot_id": assets.store.row["id"], "private": True},
    )
    assets.store.save(master_key=key, state="ready", error_message=None)
    assets.store.project_state("ready", "render", 100)
    return "ready"
