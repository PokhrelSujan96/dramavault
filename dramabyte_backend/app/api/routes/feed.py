from collections.abc import Mapping
from uuid import UUID

from fastapi import APIRouter, Depends

from app.api.dependencies import project_repository
from app.api.schemas import PublishedFeedResponse, PublishedProjectResponse
from app.infrastructure.adapters.r2 import R2Storage
from app.infrastructure.repositories.projects import ProjectRepository

router = APIRouter()


@router.get("", response_model=PublishedFeedResponse)
async def published_feed(
    repository: ProjectRepository = Depends(project_repository),
) -> PublishedFeedResponse:
    projects = await (
        repository.client.table("projects")
        .select("id,title,premise,language,aspect_ratio")
        .eq("status", "published")
        .order("updated_at", desc=True)
        .execute()
    )
    items = []
    storage = R2Storage()
    for raw_project in projects.data:
        if not isinstance(raw_project, Mapping):
            continue
        project = dict(raw_project)
        project_id = str(project.get("id", ""))
        job = await (
            repository.client.table("generation_jobs")
            .select("output")
            .eq("project_id", project_id)
            .eq("provider", "dramabyte-published")
            .eq("status", "completed")
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )
        if not job.data or not isinstance(job.data[0], Mapping):
            continue
        output = job.data[0].get("output")
        if not isinstance(output, Mapping) or not output.get("key"):
            continue
        video_variants: dict[str, str] = {}
        raw_tracks = output.get("audio_tracks")
        if isinstance(raw_tracks, Mapping):
            for language, raw_track in raw_tracks.items():
                if isinstance(raw_track, Mapping) and raw_track.get("key"):
                    video_variants[str(language)] = storage.published_url(
                        str(raw_track["key"]),
                        str(raw_track.get("revision", "")) or None,
                    )
        items.append(
            PublishedProjectResponse(
                id=UUID(project_id),
                title=str(project.get("title", "")),
                premise=str(project.get("premise", "")),
                language=str(project.get("language", "en")),
                aspect_ratio=str(project.get("aspect_ratio", "9:16")),
                video_url=storage.published_url(
                    str(output["key"]), str(output.get("revision", "")) or None
                ),
                video_revision=str(output.get("revision", "")),
                video_variants=video_variants,
            )
        )
    return PublishedFeedResponse(items=items)
