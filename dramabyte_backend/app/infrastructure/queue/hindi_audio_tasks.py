from app.application.hindi_audio import HindiAudioRunner
from app.core.config import settings
from app.infrastructure.queue.celery_app import celery_app
from supabase import create_client


@celery_app.task(name="dramabyte.localize_hindi")
def generate_hindi_audio(job_id: str) -> str:
    database = create_client(settings.supabase_url, settings.supabase_service_role_key)
    return HindiAudioRunner(database).run(job_id)
