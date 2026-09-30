from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any, cast

from app.domain.narration_timing import TimedWord, normalize_word
from app.infrastructure.adapters.fish_audio import FishAudioProvider
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.editor_audio_rendering import fit_audio, retime_captions
from app.infrastructure.production_lock import ProductionLock
from app.infrastructure.rendering import download
from app.infrastructure.speech_alignment import align_narration, alignment_dependencies
from app.infrastructure.voice_validation import validate_voice
from supabase import Client


class EditorAudioRunner:
    def __init__(self, client: Client) -> None:
        self.client = client

    def latest(self, project_id: str, provider: str) -> dict[str, Any]:
        rows = (
            self.client.table("generation_jobs")
            .select("*")
            .eq("project_id", project_id)
            .eq("provider", provider)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
            .data
        )
        if not rows:
            raise ValueError("Clean master and saved captions are required")
        return dict(cast(dict[str, Any], rows[0]))

    def run(self, job_id: str) -> str:
        row: Any = (
            self.client.table("generation_jobs")
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
                self.client.table("generation_jobs")
                .update({"status": "processing"})
                .eq("id", job_id)
                .eq("status", "queued")
                .execute()
                .data
            )
            if not claimed:
                return "already claimed"
            try:
                return self.replace(
                    job_id, project_id, row["input"]["reference_id"], lease
                )
            except Exception:
                self.client.table("generation_jobs").update(
                    {
                        "status": "failed",
                        "error_message": (
                            "Voice replacement failed. Original video/audio retained. "
                            "Check worker logs before retrying; Fish may have charged "
                            "the request."
                        ),
                    }
                ).eq("id", job_id).eq("status", "processing").execute()
                raise

    def replace(
        self, job_id: str, project_id: str, reference: str, lease: ProductionLock
    ) -> str:
        project: Any = (
            self.client.table("projects")
            .select("*")
            .eq("id", project_id)
            .single()
            .execute()
            .data
        )
        if project["status"] not in {"ready", "published"}:
            raise ValueError("Project is no longer ready for audio editing")
        preview = self.latest(project_id, "cloudflare-r2-preview")
        editor = self.latest(project_id, "dramabyte-editor")
        metadata = dict(preview["output"])
        baseline = metadata.get("alignment")
        if not baseline:
            runs: Any = (
                self.client.table("production_runs")
                .select("alignment")
                .eq("project_id", project_id)
                .order("created_at", desc=True)
                .limit(1)
                .execute()
                .data
            )
            baseline = runs[0]["alignment"] if runs else None
        old = [TimedWord.model_validate(word) for word in baseline or []]
        if not old:
            raise ValueError("Original narration alignment is unavailable")
        if [normalize_word(word.text) for word in old] != [
            normalize_word(word) for word in project["script"].split()
        ]:
            raise ValueError("Script changed since generation; original audio retained")
        alignment_dependencies()
        storage = R2Storage()
        with TemporaryDirectory(prefix="dramabyte-voice-edit-") as folder:
            root = Path(folder)
            master, voice, output = (
                root / "master.mp4",
                root / "voice.mp3",
                root / "replacement.mp4",
            )
            download(storage.signed_url(metadata["key"]), master)
            lease.ensure()
            voice.write_bytes(
                FishAudioProvider().create_voice(project["script"], reference)
            )
            validate_voice(voice)
            seconds = fit_audio(master, voice, output)
            validate_voice(output)
            new = align_narration(
                output, project["script"], project["language"], seconds
            )
            state = retime_captions(editor["output"], old, new, seconds)
            lease.ensure()
            key = f"private/editor-audio/{project_id}/{job_id}.mp4"
            storage.upload(output, key, "video/mp4")
            metadata.update(
                {
                    "key": key,
                    "private": True,
                    "reference_id": reference,
                    "alignment": [word.model_dump() for word in new],
                    "previous_key": metadata["key"],
                }
            )
            lease.ensure()
            self.client.rpc(
                "commit_editor_audio",
                {
                    "audio_job": job_id,
                    "expected_preview": preview["id"],
                    "expected_editor": editor["id"],
                    "preview_output": metadata,
                    "editor_output": state,
                },
            ).execute()
        return key
