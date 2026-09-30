import { updateQueries } from "./query-cache";
import type { StoryProject } from "./project-types";

type Row = { id: string };
type List = { items: Row[]; total?: number };

export function cacheStoryPreset(project: StoryProject, series: Row) {
  updateQueries((key, cached) => {
    const row = key === "/admin/series" ? series
      : key === "/projects" || key.startsWith("/admin/videos") ? project : undefined;
    if (!row) return cached;
    const list = cached as List;
    if (!Array.isArray(list.items)) return cached;
    if (list.items.some((item) => item.id === row.id)) {
      return { ...list, items: list.items.map((item) => item.id === row.id ? row : item) };
    }
    if (key.includes("page=") && !/[?&]page=1(?:&|$)/.test(key)) return cached;
    return { ...list, items: [row, ...list.items], total: (list.total ?? list.items.length) + 1 };
  });
}
