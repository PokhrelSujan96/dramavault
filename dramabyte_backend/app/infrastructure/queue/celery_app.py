from celery import Celery

from app.core.config import settings

celery_app = Celery(
    "dramabyte",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
    include=[
        "app.infrastructure.queue.tasks",
        "app.infrastructure.queue.editor_audio_tasks",
        "app.infrastructure.queue.hindi_audio_tasks",
    ],
)
celery_app.conf.update(
    task_default_queue="default",
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    task_track_started=True,
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    worker_prefetch_multiplier=1,
    broker_connection_retry_on_startup=True,
    task_routes={
        "dramabyte.generate": {"queue": "default"},
        "dramabyte.run_stage": {"queue": "default"},
    },
)

if not settings.is_production:
    celery_app.conf.worker_pool = "solo"
    celery_app.conf.worker_concurrency = 1
