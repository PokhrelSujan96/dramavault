import { apiRequest } from "./api-client";
import { updateQueries, loadQuery, cachedData } from "./query-cache";

type Row = Record<string, unknown>;
type List = { items: Row[]; total?: number };
function isList(data: unknown): data is List {
  return !!data && typeof data === "object" && "items" in data && Array.isArray(data.items);
}
function projectFromCache(id: unknown) {
  let project: Row | undefined;
  updateQueries((key, data) => {
    if ((key.startsWith("/admin/videos") || key === "/projects") && isList(data)) {
      project ??= data.items.find((item) => item.id === id);
    }
    return data;
  });
  return project;
}
function patchList(data: List, id: string, patch: Row | null) {
  const found = data.items.some((item) => item.id === id);
  if (!found) return data;
  const items = patch ? data.items.map((item) => item.id === id ? { ...item, ...patch } : item) : data.items.filter((item) => item.id !== id);
  if (items.some((item) => "episode_number" in item)) items.sort((a, b) => Number(a.episode_number) - Number(b.episode_number));
  return { ...data, items, total: (data.total ?? data.items.length) - (patch ? 0 : 1) };
}
export function optimisticChange(endpoint: string, method: string, body?: unknown, temporaryId = crypto.randomUUID()) {
  const values = (body ?? {}) as Row;
  const parts = endpoint.split("/");
  const kind = parts[2];
  const id = parts[3];
  const project = kind === "series" && parts[4] === "episodes" ? projectFromCache(values.project_id) : undefined;
  const now = new Date().toISOString();
  return { temporaryId, rollback: updateQueries((key, data) => {
    if (kind === "users") {
      let patch: Row = values;
      if (method === "DELETE") patch = { deleted_at: now, is_suspended: true };
      if (parts[4] === "restore") patch = { deleted_at: null, is_suspended: false };
      const coins = parts[4] === "coins";
      if (key === `/admin/users/${id}` && data && typeof data === "object" && "profile" in data) {
        const detail = data as { profile: Row; transactions: Row[] };
        const profile = { ...detail.profile, ...(!coins ? patch : { coins: Number(detail.profile.coins) + Number(values.amount) }) };
        return { ...detail, profile, transactions: coins ? [{ id: temporaryId, ...values, balance_after: profile.coins, created_at: now }, ...detail.transactions] : detail.transactions };
      }
      if (key.startsWith("/admin/users?") && isList(data)) {
        const user = data.items.find((item) => item.id === id);
        return patchList(data, id, coins && user ? { coins: Number(user.coins) + Number(values.amount) } : patch);
      }
    }
    if (kind === "videos" && isList(data) && (key.startsWith("/admin/videos") || key === "/projects")) return patchList(data, id, method === "DELETE" ? null : values);
    if (kind === "videos" && key.endsWith("/episodes") && isList(data)) {
      const items = method === "DELETE" ? data.items.filter((item) => item.project_id !== id) : data.items.map((item) => item.project_id === id ? { ...item, projects: { ...(item.projects as Row), ...values } } : item);
      return items.some((item, index) => item !== data.items[index]) || items.length !== data.items.length ? { ...data, items } : data;
    }
    if (kind === "episodes" && key.endsWith("/episodes") && isList(data)) return patchList(data, id, method === "DELETE" ? null : values);
    if (kind === "comments" && key.startsWith("/admin/comments") && isList(data)) return patchList(data, id, values);
    if (kind === "series" && key === "/admin/series" && isList(data)) {
      if (!id && method === "POST") return { ...data, items: [{ id: temporaryId, ...values, created_at: now }, ...data.items], total: (data.total ?? data.items.length) + 1 };
      if (!parts[4]) return patchList(data, id, method === "DELETE" ? null : values);
    }
    if (kind === "series" && parts[4] === "episodes" && key === endpoint && isList(data) && project) {
      return { ...data, items: [...data.items, { id: temporaryId, ...values, projects: project }].sort((a, b) => Number(a.episode_number) - Number(b.episode_number)) };
    }
    return data;
  }) };
}
let writing = false;
export async function writeManagement(endpoint: string, method: string, body?: unknown) {
  if (writing) throw new Error("Please wait for the current change to finish saving.");
  writing = true;
  const change = optimisticChange(endpoint, method, body);
  try {
    const response = await apiRequest<Row | undefined>(endpoint, { method, body });
    if (response && typeof response === "object") updateQueries((key, data) => {
      const userId = endpoint.split("/")[3];
      if (key === `/admin/users/${userId}` && data && typeof data === "object" && "profile" in data) {
        const detail = data as { profile: Row; transactions: Row[] };
        return endpoint.endsWith("/coins")
          ? { ...detail, profile: { ...detail.profile, coins: response.balance_after }, transactions: detail.transactions.map((item) => item.id === change.temporaryId ? response : item) }
          : { ...detail, profile: response };
      }
      if (endpoint.endsWith("/coins") && key.startsWith("/admin/users?") && isList(data)) return patchList(data, userId, { coins: response.balance_after });
      if (isList(data)) {
        const matches = endpoint.startsWith("/admin/comments") ? key.startsWith("/admin/comments") : endpoint.startsWith("/admin/series") ? key.startsWith("/admin/series") : endpoint.startsWith("/admin/users") ? key.startsWith("/admin/users") : endpoint.startsWith("/admin/episodes") ? key.endsWith("/episodes") : key.startsWith("/admin/videos") || key === "/projects";
        if (matches) return patchList(data, String(method === "POST" ? change.temporaryId : response.id), response);
      }
      return data;
    });
    for (const key of ["/admin/overview", "/admin/series"]) {
      if (cachedData(key) !== undefined && !endpoint.startsWith("/admin/users")) void loadQuery(key, () => apiRequest(key), true);
    }
    return response;
  } catch (cause) { change.rollback(); throw cause; }
  finally { writing = false; }
}
