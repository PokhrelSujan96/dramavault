import { useState } from "react";
import type { RecordList } from "@/components/management/management-types";
import { writeManagement } from "@/lib/optimistic-management";
import { useCachedQuery } from "./use-cached-query";

export function useManagement<T>(path: string) {
  const query = useCachedQuery<RecordList<T>>(path);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  async function mutate(endpoint: string, method: string, body?: unknown) {
    setSaving(true); setError("");
    try { await writeManagement(endpoint, method, body); return true; }
    catch (cause) { setError(cause instanceof Error ? cause.message : "Action failed"); return false; }
    finally { setSaving(false); }
  }
  return { items: query.data?.items ?? [], total: query.data?.total ?? query.data?.items.length ?? 0, error: error || query.error, busy: saving || (!query.data && query.loading), reload: query.reload, mutate };
}
