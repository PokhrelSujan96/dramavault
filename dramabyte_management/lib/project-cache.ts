import type { ProjectDraft, StoryProject } from "./project-types";
import { updateQueries } from "./query-cache";

type Projects = { items: StoryProject[]; total?: number };
export function changeProject(id: string, values: Partial<StoryProject>, insert = false) {
  return updateQueries((key, data) => {
    if (key !== "/projects" && !key.startsWith("/admin/videos")) return data;
    const list = data as Projects;
    if (!Array.isArray(list.items)) return data;
    if (insert) {
      if (key.includes("page=") && !/[?&]page=1(?:&|$)/.test(key)) return data;
      return { ...list, items: [values as StoryProject, ...list.items], total: (list.total ?? list.items.length) + 1 };
    }
    if (!list.items.some((project) => project.id === id)) return data;
    return { ...list, items: list.items.map((project) => project.id === id ? { ...project, ...values } : project) };
  });
}
export function draftProject(draft: ProjectDraft): StoryProject {
  return { ...draft, id: crypto.randomUUID(), owner_id: "", status: "draft", current_stage: "script", progress: 0, created_at: new Date().toISOString(), updated_at: new Date().toISOString() };
}

export function syncProjectLists(source: string, response: unknown) {
  if (source !== "/projects" && !source.startsWith("/admin/videos")) return;
  const incoming = response as Projects;
  if (!Array.isArray(incoming.items)) return;
  const byId = new Map(incoming.items.map((project) => [project.id, project]));
  updateQueries((key, cached) => {
    if (key === source || (key !== "/projects" && !key.startsWith("/admin/videos"))) return cached;
    const list = cached as Projects;
    if (!Array.isArray(list.items)) return cached;
    return { ...list, items: list.items.map((project) => byId.get(project.id) ?? project) };
  });
}
