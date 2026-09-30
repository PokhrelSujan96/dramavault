from collections.abc import Mapping
from typing import Any

from postgrest.exceptions import APIError

from app.core.config import settings
from app.domain.hybrid import revision
from supabase import Client


class ProductionStore:
    def __init__(self, database: Client) -> None:
        self.database = database

    def validate_schema(self) -> None:
        try:
            self.database.table("production_runs").select(
                "environment_assets,environment_requests"
            ).limit(0).execute()
        except APIError as error:
            raise ValueError(
                "Apply migration 0012_narrated_school_template.sql before production"
            ) from error

    def project(self, project_id: str) -> dict[str, Any]:
        result = (
            self.database.table("projects")
            .select("*")
            .eq("id", project_id)
            .single()
            .execute()
        )
        if not isinstance(result.data, Mapping):
            raise ValueError("Invalid project response")
        return dict(result.data)

    def context(self, project_id: str) -> list[dict[str, Any]]:
        episodes = (
            self.database.table("episodes")
            .select("series_id")
            .eq("project_id", project_id)
            .execute()
            .data
        )
        if not episodes or not isinstance(episodes[0], Mapping):
            raise ValueError("Assign this draft to a series before generation")
        cast = (
            self.database.table("series_characters")
            .select("*")
            .eq("series_id", episodes[0]["series_id"])
            .order("id")
            .execute()
            .data
        )
        if not cast:
            raise ValueError("Add approved character reference portraits to the series")
        return [dict(row) for row in cast if isinstance(row, Mapping)]

    def ensure_series_budget(self, project_id: str) -> None:
        assigned = (
            self.database.table("episodes")
            .select("series_id")
            .eq("project_id", project_id)
            .single()
            .execute()
            .data
        )
        if not isinstance(assigned, Mapping):
            raise ValueError("Assign this draft to a series before generation")
        episodes = (
            self.database.table("episodes")
            .select("id")
            .eq("series_id", assigned["series_id"])
            .execute()
            .data
        )
        projected = len(episodes) * settings.hybrid_episode_budget_cents
        if projected > settings.hybrid_series_budget_cents:
            raise ValueError("Series exceeds configured generation budget")

    def run(self, project: dict[str, Any]) -> dict[str, Any]:
        cast = self.context(str(project["id"]))
        fingerprint = revision(
            project["script"],
            project["aspect_ratio"],
            cast,
            settings.fish_audio_reference_id,
        )
        query = (
            self.database.table("production_runs")
            .select("*")
            .eq("project_id", project["id"])
            .eq("revision", fingerprint)
            .execute()
        )
        if query.data and isinstance(query.data[0], Mapping):
            return dict(query.data[0])
        created = (
            self.database.table("production_runs")
            .insert(
                {
                    "project_id": project["id"],
                    "revision": fingerprint,
                    "cast_snapshot": cast,
                }
            )
            .execute()
            .data[0]
        )
        if not isinstance(created, Mapping):
            raise ValueError("Invalid production response")
        return dict(created)

    def update(self, table: str, identifier: str, values: dict[str, Any]) -> None:
        self.database.table(table).update(values).eq("id", identifier).execute()

    def shots(self, run_id: str) -> list[dict[str, Any]]:
        result = (
            self.database.table("production_shots")
            .select("*")
            .eq("run_id", run_id)
            .order("shot_index")
            .execute()
        )
        return [dict(row) for row in result.data if isinstance(row, Mapping)]

    def job(
        self, project_id: str, stage: str, provider: str, output: dict[str, Any]
    ) -> None:
        self.database.table("generation_jobs").insert(
            {
                "project_id": project_id,
                "stage": stage,
                "provider": provider,
                "status": "completed",
                "output": output,
            }
        ).execute()
