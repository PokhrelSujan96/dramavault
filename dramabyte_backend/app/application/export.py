from collections.abc import Mapping
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any
from uuid import uuid4

from app.api.editor_schemas import EditorState
from app.infrastructure.adapters.openverse import OpenverseMusicProvider
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.rendering import create_ass, download
from app.infrastructure.video_dimensions import video_dimensions
from app.infrastructure.video_export import render_export
from supabase import Client


class ExportRunner:
    def __init__(self, database: Client) -> None:
        self.database = database

    def run(self, project_id: str) -> str:
        project = (
            self.database.table("projects")
            .select("*")
            .eq("id", project_id)
            .single()
            .execute()
        )
        if (
            isinstance(project.data, Mapping)
            and project.data.get("production_mode") == "dialogue_pilot"
        ):
            raise ValueError("Dialogue pilots are private and cannot be published")
        state = self._latest(project_id, "dramabyte-editor")
        preview = self._latest(project_id, "cloudflare-r2-preview")
        key = preview.get("key")
        if not key:
            raise RuntimeError("Clean production master is unavailable")
        storage = R2Storage()
        with TemporaryDirectory(prefix="dramabyte-export-") as directory:
            root = Path(directory)
            master = root / "master.mp4"
            subtitles = root / "captions.ass"
            final = root / "published.mp4"
            music_file = root / "background-music"
            download(storage.signed_url(str(key)), master)
            editor = EditorState.model_validate(state)
            aspect = str(
                project.data.get("aspect_ratio", "9:16")
                if isinstance(project.data, Mapping)
                else "9:16"
            )
            editor_data = editor.model_dump(mode="json")
            overlays = editor_data["overlays"]
            image_overlays = []
            text_overlays = []
            for index, item in enumerate(overlays):
                if item["kind"] == "text":
                    text_overlays.append(item)
                    continue
                asset_key = item.get("asset_key")
                asset_prefix = f"private/editor/{project_id}/"
                if not isinstance(asset_key, str) or not asset_key.startswith(
                    asset_prefix
                ):
                    raise ValueError("An image overlay is missing its uploaded asset")
                image_path = root / f"overlay-{index}{Path(asset_key).suffix}"
                download(storage.signed_url(asset_key), image_path)
                image_overlays.append({**item, "path": image_path})
            create_ass(
                [item.model_dump() for item in editor.captions],
                editor.style.model_dump(),
                subtitles,
                aspect,
                text_overlays,
            )
            music = editor.music.model_dump(mode="json") if editor.music else None
            track = None
            if music:
                track = OpenverseMusicProvider().download(
                    str(music["track_id"]), music_file
                )
                if track["license"] != music["license"]:
                    raise ValueError("Track license changed; choose another track")
            sound_effect_files = []
            effect_attributions = []
            provider = OpenverseMusicProvider()
            for index, effect in enumerate(editor.sound_effects):
                effect_path = root / f"sound-effect-{index}.audio"
                metadata = provider.download(
                    effect.track_id, effect_path, category="sound_effect"
                )
                if metadata["license"] != effect.license:
                    raise ValueError("Sound-effect license changed; choose another")
                sound_effect_files.append((effect_path, effect.model_dump()))
                effect_attributions.append(
                    f"{metadata['attribution']} — {metadata['license_url']} — "
                    f"{metadata['source_url']}"
                )
            previous = self._latest_completed(project_id, "dramabyte-published")
            revision = str(uuid4())
            public_key = f"public/productions/{project_id}/published/{revision}.mp4"
            render_export(
                master,
                subtitles,
                final,
                music_file if track else None,
                music,
                "; ".join(
                    [
                        value
                        for value in [
                            track["attribution"] if track else "",
                            *effect_attributions,
                        ]
                        if value
                    ]
                ),
                aspect,
                image_overlays,
                sound_effect_files,
            )
            storage.upload_revision(final, public_key, "video/mp4", revision)
            url = storage.published_url(public_key, revision)
            localization = self._latest(project_id, "dramabyte-localization-hi")
            localized_video = None
            if localization.get("audio_key"):
                hindi_audio = root / "narration-hi.mp3"
                hindi_ass = root / "captions-hi.ass"
                hindi_final = root / "published-hi.mp4"
                download(
                    storage.signed_url(str(localization["audio_key"])), hindi_audio
                )
                hindi_data = editor.model_dump(mode="python")
                hindi_data["captions"] = localization.get("captions", [])
                hindi_editor = EditorState.model_validate(hindi_data)
                create_ass(
                    [item.model_dump() for item in hindi_editor.captions],
                    hindi_editor.style.model_dump(),
                    hindi_ass,
                    aspect,
                    text_overlays,
                )
                hindi_revision = str(uuid4())
                hindi_key = (
                    f"public/productions/{project_id}/localized/hi/{hindi_revision}.mp4"
                )
                render_export(
                    master,
                    hindi_ass,
                    hindi_final,
                    music_file if track else None,
                    music,
                    "; ".join(
                        [
                            value
                            for value in [
                                track["attribution"] if track else "",
                                *effect_attributions,
                            ]
                            if value
                        ]
                    ),
                    aspect,
                    image_overlays,
                    sound_effect_files,
                    narration=hindi_audio,
                )
                storage.upload_revision(
                    hindi_final, hindi_key, "video/mp4", hindi_revision
                )
                localized_video = {
                    "key": hindi_key,
                    "revision": hindi_revision,
                    "audio_key": localization["audio_key"],
                    "voice_id": localization.get("voice_id", ""),
                    "model_id": localization.get("model_id", "s2.1-pro-free"),
                }
        width, height = video_dimensions(aspect)
        published: dict[str, Any] = {
            "key": public_key,
            "url": url,
            "revision": revision,
            "width": width,
            "height": height,
            "audio": "narration+music+sound-effects"
            if track and effect_attributions
            else "narration+music"
            if track
            else "narration+sound-effects"
            if effect_attributions
            else "narration",
            "captions_burned": True,
            "audio_tracks": {
                "en": {"key": public_key, "revision": revision},
                **({"hi": localized_video} if localized_video else {}),
            },
        }
        if track:
            attribution = track["attribution"] or (
                f"{track['title']} by {track['creator']} — "
                f"CC {track['license'].upper()} {track['license_version']}"
            )
            published["music_attribution"] = {
                "track_id": track["id"],
                "title": track["title"],
                "attribution": attribution,
                "creator": track["creator"],
                "license": track["license"],
                "license_version": track["license_version"],
                "license_url": track["license_url"],
                "source_url": track["source_url"],
            }
        if effect_attributions:
            published["sound_effect_attribution"] = effect_attributions
        self._job(project_id, published, previous)
        self.database.table("projects").update(
            {"status": "published", "current_stage": "publish", "progress": 100}
        ).eq("id", project_id).execute()
        return url

    def _latest(self, project_id: str, provider: str) -> dict[str, Any]:
        query = (
            self.database.table("generation_jobs")
            .select("id,output")
            .eq("project_id", project_id)
            .eq("provider", provider)
        )
        if provider == "dramabyte-localization-hi":
            query = query.eq("status", "completed")
        response = query.order("created_at", desc=True).limit(1).execute()
        if not response.data or not isinstance(response.data[0], Mapping):
            return {}
        row = response.data[0]
        output = row.get("output")
        return (
            {**dict(output), "job_id": row.get("id")}
            if isinstance(output, Mapping)
            else {}
        )

    def _latest_completed(self, project_id: str, provider: str) -> dict[str, Any]:
        response = (
            self.database.table("generation_jobs")
            .select("id,output")
            .eq("project_id", project_id)
            .eq("provider", provider)
            .eq("status", "completed")
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )
        if not response.data or not isinstance(response.data[0], Mapping):
            return {}
        row = response.data[0]
        output = row.get("output")
        return (
            {**dict(output), "job_id": row.get("id")}
            if isinstance(output, Mapping)
            else {}
        )

    def _job(
        self, project_id: str, output: dict[str, Any], previous: dict[str, Any]
    ) -> None:
        if previous.get("job_id"):
            self.database.table("generation_jobs").update(
                {"status": "completed", "output": output, "error_message": None}
            ).eq("id", previous["job_id"]).execute()
            return
        self.database.table("generation_jobs").insert(
            {
                "project_id": project_id,
                "stage": "publish",
                "provider": "dramabyte-published",
                "status": "completed",
                "output": output,
            }
        ).execute()
