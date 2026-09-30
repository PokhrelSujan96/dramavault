from uuid import UUID

from fastapi import HTTPException
from postgrest.types import JSON

from app.domain.models import PipelineStage, ProjectStatus, StoryProject
from supabase import AsyncClient


class ProjectRepository:
    def __init__(self, client: AsyncClient) -> None:
        self.client = client

    async def list(self, owner_id: UUID) -> list[StoryProject]:
        response = await (
            self.client.table("projects")
            .select("*")
            .eq("owner_id", str(owner_id))
            .order("updated_at", desc=True)
            .execute()
        )
        return [StoryProject.model_validate(item) for item in response.data]

    async def get(self, project_id: UUID, owner_id: UUID | None) -> StoryProject:
        query = self.client.table("projects").select("*").eq("id", str(project_id))
        if owner_id is not None:
            query = query.eq("owner_id", str(owner_id))
        response = await query.maybe_single().execute()
        if response is None or response.data is None:
            raise HTTPException(status_code=404, detail="Project not found")
        return StoryProject.model_validate(response.data)

    async def create(self, project: StoryProject) -> StoryProject:
        response = (
            await self.client.table("projects")
            .insert(project.model_dump(mode="json"))
            .execute()
        )
        return StoryProject.model_validate(response.data[0])

    async def mark_queued(
        self,
        project_id: UUID,
        stage: PipelineStage | None,
    ) -> None:
        values = {"status": ProjectStatus.queued.value}
        if stage is not None:
            values["current_stage"] = stage.value
        await (
            self.client.table("projects")
            .update(values)
            .eq("id", str(project_id))
            .execute()
        )

    async def update(
        self,
        project_id: UUID,
        owner_id: UUID | None,
        values: JSON,
    ) -> StoryProject:
        query = self.client.table("projects").update(values).eq("id", str(project_id))
        if owner_id is not None:
            query = query.eq("owner_id", str(owner_id))
        response = await query.execute()
        if not response.data:
            raise HTTPException(status_code=404, detail="Project not found")
        return StoryProject.model_validate(response.data[0])
