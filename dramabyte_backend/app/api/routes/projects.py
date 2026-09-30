from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.dependencies import project_repository
from app.api.schemas import (
    CreateProjectBody,
    ProjectListResponse,
    ProjectResponse,
    UpdateProjectBody,
)
from app.core.security import Principal, require_admin
from app.domain.models import StoryProject
from app.infrastructure.production_guard import production_guard
from app.infrastructure.repositories.projects import ProjectRepository

router = APIRouter()


@router.get("", response_model=ProjectListResponse)
async def list_projects(
    principal: Principal = Depends(require_admin),
    repository: ProjectRepository = Depends(project_repository),
) -> ProjectListResponse:
    items = await repository.list(UUID(principal.user_id))
    return ProjectListResponse(items=items)


@router.post("", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_project(
    body: CreateProjectBody,
    principal: Principal = Depends(require_admin),
    repository: ProjectRepository = Depends(project_repository),
) -> ProjectResponse:
    project = StoryProject(owner_id=UUID(principal.user_id), **body.model_dump())
    return ProjectResponse(project=await repository.create(project))


@router.get("/{project_id}", response_model=ProjectResponse)
async def get_project(
    project_id: UUID,
    principal: Principal = Depends(require_admin),
    repository: ProjectRepository = Depends(project_repository),
) -> ProjectResponse:
    project = await repository.get(project_id, None)
    return ProjectResponse(project=project)


@router.patch("/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: UUID,
    body: UpdateProjectBody,
    principal: Principal = Depends(require_admin),
    repository: ProjectRepository = Depends(project_repository),
) -> ProjectResponse:
    async with production_guard(str(project_id)):
        current = await repository.get(project_id, None)
        if current.status in {"queued", "generating", "published"}:
            raise HTTPException(409, "Wait for production or create a new draft")
        values = body.model_dump(exclude_none=True)
        project = await repository.update(project_id, None, values)
        return ProjectResponse(project=project)
