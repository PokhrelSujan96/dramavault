from pathlib import Path
from tempfile import TemporaryDirectory

from app.application.hybrid_preparation import HybridPreparation
from app.application.motion_batch import generate_motion
from app.application.narrated_metadata import save_narrated_metadata
from app.application.narrated_preview import save_preview
from app.core.logging import logger
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.environment_assets import EnvironmentAssets
from app.infrastructure.hybrid_assets import HybridAssets
from app.infrastructure.hybrid_rendering import (
    assemble,
    frame_duration,
    render_shot,
    validate_master,
)
from app.infrastructure.production_lock import ProductionLock
from app.infrastructure.production_preflight import production_preflight
from app.infrastructure.production_store import ProductionStore
from app.infrastructure.rendering import download
from supabase import Client

log = logger(__name__)


class ProductionRunner:
    def __init__(self, database: Client) -> None:
        self.store = ProductionStore(database)
        self.current = "storyboard"

    def run(self, project_id: str) -> str:
        with ProductionLock(project_id) as lease:
            try:
                return self._run(project_id, lease)
            except Exception as error:
                log.error(
                    "hybrid_failed",
                    project_id=project_id,
                    stage=self.current,
                    error_type=type(error).__name__,
                )
                self.store.update(
                    "projects",
                    project_id,
                    {
                        "status": "failed",
                        "current_stage": self.current,
                    },
                )
                self.store.database.table("generation_jobs").insert(
                    {
                        "project_id": project_id,
                        "stage": self.current,
                        "provider": "dramabyte-hybrid",
                        "status": "failed",
                        "output": {},
                        "error_message": str(error)[:1000],
                    }
                ).execute()
                raise

    def _run(self, project_id: str, lease: ProductionLock) -> str:
        project = self.store.project(project_id)
        if project.get("production_mode") == "dialogue_pilot":
            raise ValueError("Use dialogue production for this private pilot")
        if project["status"] == "published":
            return "published"
        self.store.validate_schema()
        self.store.ensure_series_budget(project_id)
        production_preflight()
        if project["aspect_ratio"] != "9:16":
            raise ValueError("Hybrid drama production requires portrait 9:16")
        if not project["script"].strip():
            raise ValueError("A narration script is required")
        run = self.store.run(project)
        storage = R2Storage()
        if run.get("master_key"):
            self.store.update(
                "projects", project_id, {"status": "ready", "progress": 100}
            )
            return storage.signed_url(run["master_key"])
        with TemporaryDirectory(prefix="dramabyte-hybrid-") as directory:
            root = Path(directory)
            self._progress(project_id, "voice", 8)
            lease.ensure()
            voice, seconds, captions = HybridPreparation(self.store).prepare(
                project, run, root
            )
            assets = HybridAssets(self.store, lease)
            shots = self.store.shots(run["id"])
            EnvironmentAssets(self.store, lease).prepare(run, shots, root)
            for index, shot in enumerate(shots):
                self._progress(
                    project_id, "images", 15 + round(25 * index / len(shots))
                )
                assets.image(shot, run, project["aspect_ratio"], root)
            shots = self.store.shots(run["id"])
            if not all(shot["approved"] for shot in shots):
                self.store.update("production_runs", run["id"], {"state": "review"})
                self.store.update(
                    "projects",
                    project_id,
                    {
                        "status": "review",
                        "current_stage": "images",
                        "progress": 40,
                    },
                )
                log.info("motion_review", project_id=project_id, shots=len(shots))
                return "review"
            self._progress(project_id, "video", 40)
            motion_count = sum(shot["kind"] == "motion" for shot in shots)
            generate_motion(
                shots,
                assets,
                run,
                project["aspect_ratio"],
                root,
                lambda count: self._progress(
                    project_id, "video", 40 + round(30 * count / motion_count)
                ),
            )
            shots = self.store.shots(run["id"])
            if not all(shot["motion_approved"] for shot in shots):
                self.store.update(
                    "production_runs", run["id"], {"state": "motion_review"}
                )
                self.store.update(
                    "projects",
                    project_id,
                    {
                        "status": "review",
                        "current_stage": "video",
                        "progress": 70,
                    },
                )
                return "motion_review"
            rendered = []
            for index, shot in enumerate(shots):
                lease.ensure()
                self._progress(
                    project_id, "render", 70 + round(20 * index / len(shots))
                )
                key = (
                    shot["video_key"]
                    if shot["kind"] == "motion"
                    else shot["image_key"]
                )
                extension = "mp4" if shot["kind"] == "motion" else "png"
                source = root / f"source-{index}.{extension}"
                output = root / f"shot-{index}.mp4"
                download(storage.signed_url(key), source)
                render_shot(
                    source,
                    output,
                    frame_duration(shot["start_seconds"], shot["end_seconds"]),
                    shot["kind"],
                    "9:16",
                )
                rendered.append(output)
            final = root / "master.mp4"
            assemble(rendered, voice, final, seconds)
            validate_master(final, seconds, "9:16")
            save_preview(final, project_id, captions)
            lease.ensure()
            key = f"productions/{project_id}/{run['id']}.mp4"
            self._progress(project_id, "publish", 95)
            url = storage.upload(final, key, "video/mp4")
            save_narrated_metadata(
                self.store, project_id, run["id"], key, url, captions
            )
            self.store.update(
                "production_runs", run["id"], {"master_key": key, "state": "ready"}
            )
            self.store.update(
                "projects", project_id, {"status": "ready", "progress": 100}
            )
            self.store.database.table("episodes").update(
                {
                    "duration_seconds": round(seconds),
                }
            ).eq("project_id", project_id).execute()
            log.info("hybrid_completed", project_id=project_id, shots=len(shots))
            return url

    def _progress(self, project_id: str, stage: str, progress: int) -> None:
        self.current = stage
        self.store.update(
            "projects",
            project_id,
            {
                "status": "generating",
                "current_stage": stage,
                "progress": progress,
            },
        )
