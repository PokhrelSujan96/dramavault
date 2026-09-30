from collections.abc import Mapping
from uuid import UUID

from fastapi import HTTPException

from app.domain.models import GenerationRequest, ProjectStatus
from app.infrastructure.production_guard import production_guard
from app.infrastructure.queue.tasks import start_generation
from app.infrastructure.repositories.projects import ProjectRepository


class GenerationService:
    def __init__(self, projects: ProjectRepository) -> None:
        self.projects = projects

    async def enqueue(self, request: GenerationRequest, owner_id: UUID | None) -> str:
        async with production_guard(str(request.project_id)):
            project = await self.projects.get(request.project_id, owner_id)
            if project.production_mode == "dialogue_pilot":
                raise HTTPException(409, "Use the dialogue pilot workflow")
            if project.status in {ProjectStatus.generating, ProjectStatus.queued}:
                return str(project.id)
            if request.regenerate_from:
                raise HTTPException(422, "Use shot rerolls for hybrid generation")
            if project.status == ProjectStatus.published:
                raise HTTPException(409, "Create a new draft for a published episode")
            if project.aspect_ratio != "9:16" or not project.script.strip():
                raise HTTPException(
                    422, "Hybrid production needs a portrait narration draft"
                )
            if len(project.script.split()) > 500:
                raise HTTPException(422, "Keep episode narration under 500 words")
            episode = (
                await self.projects.client.table("episodes")
                .select("series_id")
                .eq("project_id", str(project.id))
                .execute()
            )
            if not episode.data or not isinstance(episode.data[0], Mapping):
                raise HTTPException(422, "Assign this draft to a series first")
            cast = (
                await self.projects.client.table("series_characters")
                .select("id")
                .eq("series_id", str(episode.data[0]["series_id"]))
                .limit(1)
                .execute()
            )
            if not cast.data:
                raise HTTPException(
                    422,
                    "Upload approved character portraits in Story Studio's "
                    "character setup before production. No paid requests were made.",
                )
            await self.projects.mark_queued(project.id, request.regenerate_from)
        try:
            task = start_generation.apply_async(
                args=[str(project.id)],
                task_id=request.idempotency_key,
                queue="default",
            )
        except Exception as error:
            await self.projects.update(project.id, None, {"status": "failed"})
            raise HTTPException(
                503, "Queue dispatch not confirmed; check worker logs before retrying"
            ) from error
        return str(task.id)
