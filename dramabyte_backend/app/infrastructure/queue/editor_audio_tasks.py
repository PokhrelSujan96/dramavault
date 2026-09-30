from typing import Any

from app.application.editor_audio import EditorAudioRunner
from app.core.config import settings
from app.infrastructure.queue.celery_app import celery_app
from supabase import create_client


@celery_app.task(name="dramabyte.editor_audio", acks_late=False, bind=True)
def replace_editor_audio(task: Any, job_id: str) -> str:
    client = create_client(settings.supabase_url, settings.supabase_service_role_key)
    try:
        return EditorAudioRunner(client).run(job_id)
    except RuntimeError as error:
        if str(error) == "Production is already running for this project":
            raise task.retry(exc=error, countdown=3, max_retries=40) from error
        raise
