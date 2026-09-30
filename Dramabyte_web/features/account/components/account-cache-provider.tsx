"use client";

import { createContext, useContext, useState, useSyncExternalStore } from "react";
import type { AccountPanel } from "@/domain/account/navigation";
import { createPanelCache, type PanelCache } from "@/application/account/panel-cache";
import { loadNavigationPanel } from "@/features/account/actions/navigation";

const Context = createContext<PanelCache | null>(null);
export function AccountCacheProvider({ children }: { children: React.ReactNode }) {
  const [cache] = useState(() => createPanelCache(loadNavigationPanel));
  return <Context.Provider value={cache}>{children}</Context.Provider>;
}

export function useAccountCache() {
  const cache = useContext(Context);
  if (!cache) throw new Error("Account cache provider is missing");
  return cache;
}

export function useAccountPanel(panel: AccountPanel) {
  const cache = useAccountCache();
  const data = useSyncExternalStore(cache.subscribe, () => cache.snapshot(panel), () => null);
  return { cache, data };
}
