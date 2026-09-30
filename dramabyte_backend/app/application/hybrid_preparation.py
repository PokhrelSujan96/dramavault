from pathlib import Path
from typing import Any

import httpx

from app.domain.hybrid import Storyboard, shot_count
from app.domain.narration_timing import TimedWord, aligned_captions, timed_beats
from app.infrastructure.adapters.fish_audio import FishAudioProvider
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.adapters.storyboard import StoryboardProvider
from app.infrastructure.production_store import ProductionStore
from app.infrastructure.rendering import download, duration
from app.infrastructure.speech_alignment import align_narration
from app.infrastructure.voice_validation import validate_voice


class HybridPreparation:
    def __init__(self, store: ProductionStore) -> None:
        self.store = store

    def prepare(
        self, project: dict[str, Any], run: dict[str, Any], root: Path
    ) -> tuple[Path, float, list[dict[str, object]]]:
        voice = root / "voice.mp3"
        storage = R2Storage()
        if run.get("voice_key"):
            download(storage.signed_url(run["voice_key"]), voice)
        else:
            if run["voice_pending"]:
                raise RuntimeError("Ambiguous voice request; reconcile before retrying")
            self.store.update("production_runs", run["id"], {"voice_pending": True})
            try:
                voice.write_bytes(FishAudioProvider().create_voice(project["script"]))
            except httpx.HTTPStatusError as error:
                if error.response.status_code in {400, 401, 402, 403, 404, 422}:
                    self.store.update(
                        "production_runs", run["id"], {"voice_pending": False}
                    )
                raise
            key = f"hybrid/{run['id']}/voice.mp3"
            storage.upload(voice, key, "audio/mpeg")
            self.store.update(
                "production_runs",
                run["id"],
                {
                    "voice_key": key,
                    "voice_pending": False,
                },
            )
        seconds = duration(voice)
        validate_voice(voice)
        shot_count(seconds)
        self.store.update("production_runs", run["id"], {"duration_seconds": seconds})
        if run.get("alignment"):
            words = [TimedWord.model_validate(item) for item in run["alignment"]]
        else:
            words = align_narration(
                voice, project["script"], project["language"], seconds
            )
            self.store.update(
                "production_runs",
                run["id"],
                {
                    "alignment": [word.model_dump() for word in words],
                },
            )
        beats = timed_beats(words, seconds)
        if run.get("storyboard"):
            board = Storyboard.model_validate(run["storyboard"])
        else:
            board = StoryboardProvider().plan(
                project["script"], beats, run["cast_snapshot"]
            )
            self.store.update(
                "production_runs",
                run["id"],
                {
                    "storyboard": board.model_dump(mode="json"),
                    "state": "images",
                },
            )
        if not self.store.shots(run["id"]):
            self.store.database.table("production_shots").insert(
                [
                    {
                        "run_id": run["id"],
                        "shot_index": scene.index,
                        "kind": scene.kind,
                        "narration": scene.narration,
                        "prompt": scene.prompt,
                        "character_ids": [
                            str(identifier) for identifier in scene.character_ids
                        ],
                        "duration_seconds": scene.end - scene.start,
                        "start_seconds": scene.start,
                        "end_seconds": scene.end,
                        "scene_spec": scene.spec.model_dump() if scene.spec else {},
                        "motion_approved": scene.kind == "still",
                    }
                    for scene in board.scenes
                ]
            ).execute()
        return voice, seconds, aligned_captions(words)
