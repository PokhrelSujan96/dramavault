from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any, cast

from postgrest.types import JSON

from app.application.localization import HindiTranslator
from app.infrastructure.adapters.fish_audio import FishAudioProvider
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.editor_audio_rendering import fit_voice_track, hindi_captions
from app.infrastructure.production_lock import ProductionLock
from app.infrastructure.rendering import download, duration
from app.infrastructure.speech_alignment import align_narration
from app.infrastructure.voice_validation import validate_voice
from supabase import Client


class HindiAudioRunner:
    provider = "dramabyte-localization-hi"

    def __init__(self, database: Client) -> None:
        self.database = database

    def run(self, job_id: str) -> str:
        row: Any = (
            self.database.table("generation_jobs")
            .select("*")
            .eq("id", job_id)
            .single()
            .execute()
            .data
        )
        if row["status"] != "queued":
            return str(row["status"])
        project_id = str(row["project_id"])
        with ProductionLock(project_id) as lease:
            claimed = (
                self.database.table("generation_jobs")
                .update({"status": "processing"})
                .eq("id", job_id)
                .eq("status", "queued")
                .execute()
                .data
            )
            if not claimed:
                return "already claimed"
            try:
                return self._generate(
                    job_id,
                    project_id,
                    row["input"],
                    row.get("output") or {},
                    lease,
                )
            except Exception as error:
                self.database.table("generation_jobs").update(
                    {
                        "status": "failed",
                        "error_message": str(error)[:1000],
                    }
                ).eq("id", job_id).eq("status", "processing").execute()
                raise

    def _generate(
        self,
        job_id: str,
        project_id: str,
        request: dict[str, Any],
        previous: dict[str, Any],
        lease: Any,
    ) -> str:
        project: Any = (
            self.database.table("projects")
            .select("script,status,production_mode,language")
            .eq("id", project_id)
            .single()
            .execute()
            .data
        )
        if project["status"] not in {"ready", "published"}:
            raise ValueError("Finish production before adding Hindi narration")
        if project.get("production_mode") == "dialogue_pilot":
            raise ValueError("Hindi narration is available for narrated episodes")
        if not str(project.get("language", "en")).lower().startswith("en"):
            raise ValueError("Hindi localization currently requires English narration")
        script = str(project.get("script", "")).strip()
        if not script or len(script) > 30000:
            raise ValueError("Episode narration must contain 1–30,000 characters")
        voice_id = str(request.get("voice_id", "")).strip()
        if not voice_id or len(voice_id) > 100:
            raise ValueError("Choose a valid Fish Audio Hindi voice")
        master_row = self._latest(project_id, "cloudflare-r2-preview")
        if not master_row.get("key"):
            raise ValueError("Clean production master is unavailable")
        lease.ensure()
        with TemporaryDirectory(prefix="dramabyte-hindi-") as folder:
            root = Path(folder)
            master, raw, fitted = (
                root / "master.mp4",
                root / "hindi.mp3",
                root / "hindi-fit.mp3",
            )
            storage = R2Storage()
            download(storage.signed_url(str(master_row["key"])), master)
            translated = str(previous.get("translated_script", ""))
            checkpoint = {
                **previous,
                "language": "hi",
                "translated_script": translated,
                "voice_id": voice_id,
                "model_id": "s2.1-pro-free",
            }
            if not translated:
                translated = HindiTranslator().translate(script)
                checkpoint = {
                    **checkpoint,
                    "translated_script": translated,
                    "phase": "translated",
                }
                self.database.table("generation_jobs").update(
                    {"output": cast(JSON, checkpoint)}
                ).eq("id", job_id).execute()
            raw_key = str(
                previous.get("raw_audio_key")
                or f"private/localizations/{project_id}/hi/{job_id}-raw.mp3"
            )
            if previous.get("raw_audio_key") or storage.exists(raw_key):
                download(storage.signed_url(raw_key), raw)
            else:
                raw.write_bytes(FishAudioProvider().create_voice(translated, voice_id))
                storage.upload(raw, raw_key, "audio/mpeg")
                checkpoint = {
                    **checkpoint,
                    "audio_key": raw_key,
                    "raw_audio_key": raw_key,
                    "phase": "synthesized",
                }
                self.database.table("generation_jobs").update(
                    {"output": cast(JSON, checkpoint)}
                ).eq("id", job_id).execute()
            validate_voice(raw)
            seconds = fit_voice_track(master, raw, fitted)
            validate_voice(fitted)
            words = align_narration(fitted, translated, "hi", seconds)
            captions = hindi_captions(words)
            fitted_seconds = duration(fitted)
            key = f"private/localizations/{project_id}/hi/{job_id}.mp3"
            storage.upload(fitted, key, "audio/mpeg")
            lease.ensure()
        output = {
            "language": "hi",
            "language_name": "हिन्दी",
            "voice_id": voice_id,
            "model_id": "s2.1-pro-free",
            "translated_script": translated,
            "audio_key": key,
            "duration_seconds": round(fitted_seconds, 3),
            "captions": captions,
        }
        self.database.table("generation_jobs").update(
            {"status": "completed", "output": cast(JSON, output), "error_message": None}
        ).eq("id", job_id).execute()
        return key

    def _latest(self, project_id: str, provider: str) -> dict[str, Any]:
        rows: Any = (
            self.database.table("generation_jobs")
            .select("output")
            .eq("project_id", project_id)
            .eq("provider", provider)
            .eq("status", "completed")
            .order("created_at", desc=True)
            .limit(1)
            .execute()
            .data
        )
        return dict(cast(dict[str, Any], rows[0]["output"])) if rows else {}
