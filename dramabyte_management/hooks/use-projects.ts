"use client";

import { useEffect } from "react";
import { apiRequest } from "@/lib/api-client";
import type { ProjectDraft, StoryProject } from "@/lib/project-types";
import { changeProject, draftProject } from "@/lib/project-cache";
import { useCachedQuery } from "./use-cached-query";

export function useProjects() {
  const query = useCachedQuery<{ items: StoryProject[] }>("/projects");
  const { reload, data } = query;
  const projects = query.data?.items ?? [];
  const active = projects.some((item) => ["queued", "generating"].includes(item.status));
  useEffect(() => {
    if (!active) return;
    const timer = window.setTimeout(() => void reload(), 5000);
    return () => window.clearTimeout(timer);
  }, [active, data, reload]);

  const create = async (draft: ProjectDraft) => {
    const optimistic = draftProject(draft);
    const rollback = changeProject(optimistic.id, optimistic, true);
    try {
      const data = await apiRequest<{ project: StoryProject }>("/projects", { method: "POST", body: draft });
      changeProject(optimistic.id, data.project);
      return data.project;
    } catch (cause) { rollback(); throw cause; }
  };
  const update = async (projectId: string, draft: ProjectDraft) => {
    const rollback = changeProject(projectId, draft);
    try {
      const data = await apiRequest<{ project: StoryProject }>(`/projects/${projectId}`, { method: "PATCH", body: draft });
      changeProject(projectId, data.project);
      return data.project;
    } catch (cause) { rollback(); throw cause; }
  };
  return { projects, loading: !query.data && !query.error, authenticated: query.status !== 401, error: query.error, create, update, reload: query.reload };
}
