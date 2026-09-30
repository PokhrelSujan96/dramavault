import type { AccountPanel, NavigationData } from "@/domain/account/navigation";
import type { SeriesCard } from "@/domain/models";

type Loader = (panel: AccountPanel) => Promise<NavigationData>;
export function createPanelCache(loader: Loader) {
  const entries = new Map<AccountPanel, NavigationData>();
  const pending = new Map<AccountPanel, Promise<void>>();
  const revisions = new Map<AccountPanel, number>();
  const listeners = new Set<() => void>();
  const notify = () => listeners.forEach((listener) => listener());
  const snapshot = (panel: AccountPanel) => entries.get(panel) ?? null;
  const subscribe = (listener: () => void) => { listeners.add(listener); return () => { listeners.delete(listener); }; };
  const clear = () => { entries.clear(); for (const panel of ["library", "profile", "referral", "history"] as const) revisions.set(panel, (revisions.get(panel) ?? 0) + 1); pending.clear(); notify(); };
  const load = (panel: AccountPanel, refresh = false): Promise<void> => {
    if (!refresh && entries.has(panel)) return Promise.resolve();
    if (!refresh && pending.has(panel)) return pending.get(panel)!;
    const revision = (revisions.get(panel) ?? 0) + 1;
    revisions.set(panel, revision);
    const request = loader(panel).catch((): NavigationData => ({ error: "Couldn’t load your account. Please try again." })).then((data) => {
      if (revisions.get(panel) !== revision) return;
      if (data.signIn) clear();
      entries.set(panel, data);
      notify();
    }).finally(() => { if (pending.get(panel) === request) pending.delete(panel); });
    pending.set(panel, request);
    return request;
  };
  const editLibrary = (item: SeriesCard, saved: boolean) => {
    const previous = snapshot("library");
    if (previous?.library && pending.has("library")) {
      revisions.set("library", (revisions.get("library") ?? 0) + 1);
      pending.delete("library");
    }
    const original = previous?.library?.find((entry) => entry.series_id === item.series_id);
    const index = previous?.library?.findIndex((entry) => entry.series_id === item.series_id) ?? -1;
    const update = (replacement?: SeriesCard) => {
      const data = snapshot("library");
      if (!data?.library) return;
      const items = data.library.filter((entry) => entry.series_id !== item.series_id);
      if (replacement) items.splice(index < 0 ? 0 : Math.min(index, items.length), 0, replacement);
      entries.set("library", { ...data, library: items.slice(0, 200) });
      notify();
    };
    update(saved ? item : undefined);
    return {
      rollback: () => {
        if (previous?.library) update(original);
        else if (entries.has("library") || pending.has("library")) void load("library", true);
      },
      commit: () => {
        update(saved ? item : undefined);
        if (pending.has("library")) void load("library", true);
      },
    };
  };
  return { snapshot, subscribe, load, clear, editLibrary };
}
export type PanelCache = ReturnType<typeof createPanelCache>;
