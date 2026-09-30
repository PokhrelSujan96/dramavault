import math
from pathlib import Path

from app.domain.dialogue import PilotPlan
from app.infrastructure.dialogue_assets import DialogueAssets
from app.infrastructure.dialogue_direction import lipsync_arguments, motion_arguments
from app.infrastructure.rendering import _executable, _run, duration


def prepare_motion(plan: PilotPlan, assets: DialogueAssets, root: Path) -> None:
    for shot in plan.shots:
        index = shot.index
        image = assets.store.row["assets"][f"image-{index}"]
        motion = assets.generate(
            f"motion-{index}",
            "fal-ai/wan-i2v",
            motion_arguments(shot, assets.storage.signed_url(image), index + 47),
            20,
        )
        if shot.role != "dialogue":
            continue
        source, trimmed = root / f"raw-{index}.mp4", root / f"trimmed-{index}.mp4"
        assets.fetch(motion, source)
        if duration(source) + 0.02 < shot.seconds:
            raise ValueError("Speaking footage is too short; no freeze fallback")
        _run(
            [
                _executable("ffmpeg"),
                "-y",
                "-i",
                str(source),
                "-t",
                str(shot.seconds),
                "-an",
                "-c:v",
                "libx264",
                "-preset",
                "fast",
                "-crf",
                "18",
                "-pix_fmt",
                "yuv420p",
                "-vf",
                "fps=30",
                str(trimmed),
            ],
            root,
        )
        clip = assets.local(f"speaking-{index}", trimmed, "video/mp4")
        if not shot.voice_key:
            raise ValueError("Speaking shot has no prepared voice")
        assets.generate(
            f"lipsync-{index}",
            "fal-ai/sync-lipsync/v2",
            lipsync_arguments(
                assets.storage.signed_url(clip),
                assets.storage.signed_url(shot.voice_key),
            ),
            math.ceil(shot.seconds * 5),
        )
