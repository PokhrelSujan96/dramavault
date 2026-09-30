import { useState } from "react";
import { apiRequest } from "@/lib/api-client";
import type { StoryProject } from "@/lib/project-types";
import { cacheStoryPreset } from "@/lib/preset-cache";

type Props = { onPrepared: (project: StoryProject) => void };

export function SchoolStoryPreset({ onPrepared }: Props) {
  const [requestId, setRequestId] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function prepare() {
    const operation = requestId || crypto.randomUUID();
    setRequestId(operation);
    setBusy(true);
    setError("");
    try {
      const result = await apiRequest<{ project: StoryProject; series: { id: string } }>("/generation/templates/last-seat/draft", {
        method: "POST", body: { request_id: operation },
      });
      cacheStoryPreset(result.project, result.series);
      onPrepared(result.project);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Unable to prepare series");
    } finally { setBusy(false); }
  }

  return <section className="hybrid-production">
    <h3>The Last Seat · Episode 1</h3>
    <p>Create a new series and the full “The Girl in the Last Seat” story. One storyteller, cinematic school scenes with background students, no character voices, lip-sync or music. Creating this draft does not spend provider credits.</p>
    {error && <p role="alert" className="dashboard-error">{error}</p>}
    <button type="button" disabled={busy} onClick={() => void prepare()}>{busy ? "Preparing draft…" : "Create series + Episode 1 draft"}</button>
  </section>;
}
