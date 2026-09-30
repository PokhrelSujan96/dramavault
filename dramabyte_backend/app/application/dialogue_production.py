from pathlib import Path
from tempfile import TemporaryDirectory

from app.application.dialogue_finish import finish_pilot
from app.application.dialogue_motion import prepare_motion
from app.application.dialogue_preparation import prepare_dialogue
from app.core.config import settings
from app.core.logging import logger
from app.infrastructure.dialogue_assets import DialogueAssets
from app.infrastructure.dialogue_store import DialogueStore
from app.infrastructure.production_lock import ProductionLock
from app.infrastructure.production_preflight import production_preflight
from supabase import Client

log = logger(__name__)


class DialogueProduction:
    def __init__(self, database: Client) -> None:
        self.database = database

    def run(self, pilot_id: str) -> str:
        store = DialogueStore(self.database, pilot_id)
        with ProductionLock(store.row["project_id"]) as lease:
            store = DialogueStore(self.database, pilot_id)
            if store.row["master_key"]:
                store.save(state="ready")
                store.project_state("ready", "render", 100)
                return "ready"
            try:
                if not settings.dialogue_paid_enabled:
                    raise ValueError("Paid dialogue generation is disabled")
                production_preflight()
                with TemporaryDirectory(prefix="dramabyte-dialogue-") as directory:
                    root = Path(directory)
                    assets = DialogueAssets(store, lease, root)
                    store.save(state="voices", error_message=None)
                    store.project_state("generating", "voice", 10)
                    plan = prepare_dialogue(store, assets, root)
                    image_names = [
                        "location",
                        *[f"image-{shot.index}" for shot in plan.shots],
                    ]
                    if not all(
                        store.row["approvals"].get(name) for name in image_names
                    ):
                        store.save(state="review")
                        store.project_state("review", "images", 40)
                        return "review"
                    store.save(state="video")
                    store.project_state("generating", "video", 50)
                    prepare_motion(plan, assets, root)
                    motion_names = [f"clip-{shot.index}" for shot in plan.shots]
                    if not all(
                        store.row["approvals"].get(name) for name in motion_names
                    ):
                        store.save(state="motion_review")
                        store.project_state("review", "video", 80)
                        return "motion_review"
                    store.project_state("generating", "render", 90)
                    return finish_pilot(plan, assets, root)
            except Exception as error:
                store.save(state="failed", error_message=str(error)[:1000])
                store.project_state("failed", "video", 0)
                log.error(
                    "dialogue_pilot_failed",
                    pilot_id=pilot_id,
                    error_type=type(error).__name__,
                )
                raise
