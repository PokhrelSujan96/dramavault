from app.application.dialogue_production import DialogueProduction
from app.application.export import ExportRunner
from app.application.production import ProductionRunner
from app.core.config import settings
from app.infrastructure.queue.celery_app import celery_app
from supabase import create_client


@celery_app.task(name="dramabyte.dialogue_pilot")
def dialogue_pilot(pilot_id: str) -> str:
    database = create_client(settings.supabase_url, settings.supabase_service_role_key)
    return DialogueProduction(database).run(pilot_id)


@celery_app.task(name="dramabyte.generate")
def start_generation(project_id: str, start: str | None = None) -> str:
    database = create_client(
        settings.supabase_url,
        settings.supabase_service_role_key,
    )
    return ProductionRunner(database).run(project_id)


@celery_app.task(name="dramabyte.export")
def export_production(project_id: str) -> str:
    database = create_client(
        settings.supabase_url,
        settings.supabase_service_role_key,
    )
    try:
        return ExportRunner(database).run(project_id)
    except Exception as error:
        previous = (
            database.table("generation_jobs")
            .select("id")
            .eq("project_id", project_id)
            .eq("provider", "dramabyte-published")
            .eq("status", "completed")
            .limit(1)
            .execute()
        )
        has_previous_publication = bool(previous.data)
        database.table("projects").update(
            {
                "status": "published" if has_previous_publication else "failed",
                "current_stage": "publish",
                "progress": 100 if has_previous_publication else 95,
            }
        ).eq("id", project_id).execute()
        database.table("generation_jobs").insert(
            {
                "project_id": project_id,
                "stage": "publish",
                "provider": "dramabyte-published",
                "status": "failed",
                "output": {},
                "error_message": str(error)[:1000],
            }
        ).execute()
        raise
