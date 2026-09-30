import { useCallback, useEffect, useSyncExternalStore } from "react";
import { apiRequest } from "@/lib/api-client";
import { loadQuery, serverSnapshot, snapshot, subscribe } from "@/lib/query-cache";
import { syncProjectLists } from "@/lib/project-cache";

export function useCachedQuery<T>(path: string) {
  const listen = useCallback((listener: () => void) => subscribe(path, listener), [path]);
  const read = useCallback(() => snapshot<T>(path), [path]);
  const state = useSyncExternalStore(listen, read, serverSnapshot<T>);
  const fetcher = useCallback(async () => {
    const data = await apiRequest<T>(path);
    return data;
  }, [path]);
  const reload = useCallback(() => loadQuery(path, fetcher, true, (data) => syncProjectLists(path, data)), [path, fetcher]);
  useEffect(() => { void loadQuery(path, fetcher, false, (data) => syncProjectLists(path, data)); }, [path, fetcher]);
  return { ...state, reload };
}
