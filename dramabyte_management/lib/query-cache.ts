export type QuerySnapshot<T = unknown> = {
  data?: T; error: string; loading: boolean; version: number; status?: number; updatedAt?: number;
};
type Entry = { state: QuerySnapshot; listeners: Set<() => void>; request?: Promise<void> };
const entries = new Map<string, Entry>();
const empty: QuerySnapshot = { error: "", loading: false, version: 0 };

function entry(key: string) {
  let value = entries.get(key);
  if (!value) { value = { state: empty, listeners: new Set() }; entries.set(key, value); }
  return value;
}
export function snapshot<T>(key: string): QuerySnapshot<T> {
  return entry(key).state as QuerySnapshot<T>;
}
export function serverSnapshot<T>(): QuerySnapshot<T> { return empty as QuerySnapshot<T>; }
export function subscribe(key: string, listener: () => void) {
  const value = entry(key); value.listeners.add(listener);
  return () => { value.listeners.delete(listener); };
}
function publish(key: string, state: QuerySnapshot) {
  const value = entry(key); value.state = state;
  value.listeners.forEach((listener) => listener());
}
export function setQuery<T>(key: string, data: T) {
  const state = snapshot(key);
  publish(key, { data, error: "", loading: false, version: state.version + 1, updatedAt: Date.now() });
}
export async function loadQuery<T>(key: string, fetcher: () => Promise<T>, force = false, onCommit?: (data: T) => void) {
  const value = entry(key);
  if (value.request) return value.request;
  if (!force && value.state.data !== undefined) return;
  const version = value.state.version;
  publish(key, { ...value.state, error: "", loading: true });
  const request = (async () => {
    try {
      const data = await fetcher();
      if (entry(key) === value && value.state.version === version) { setQuery(key, data); onCommit?.(data); }
    } catch (cause) {
      if (entry(key) === value && value.state.version === version) {
        publish(key, { ...value.state, error: cause instanceof Error ? cause.message : "Request failed", status: cause && typeof cause === "object" && "status" in cause ? Number(cause.status) : undefined, loading: false });
      }
    }
  })();
  value.request = request;
  void request.finally(() => { if (value.request === request) value.request = undefined; });
  return request;
}
export function updateQueries(update: (key: string, data: unknown) => unknown) {
  const before = new Map<string, QuerySnapshot>();
  for (const [key, value] of entries) {
    if (value.state.data === undefined) continue;
    const next = update(key, value.state.data);
    if (next === value.state.data) continue;
    before.set(key, value.state); setQuery(key, next);
  }
  return () => {
    for (const [key, state] of before) {
      if (snapshot(key).version === state.version + 1) {
        publish(key, { ...state, loading: false, version: state.version + 2 });
      }
    }
  };
}
export function clearQueries() {
  for (const [key, value] of entries) {
    value.request = undefined;
    publish(key, { ...empty, version: value.state.version + 1 });
  }
}
export function cachedData<T>(key: string) { return snapshot<T>(key).data; }
