import { useCachedQuery } from "@/hooks/use-cached-query";
import { DialoguePilotReview } from "./dialogue-pilot-review";
import type { DialoguePilot } from "./dialogue-types";

export function DialoguePilotWorkspace({ projectId, onClose }: { projectId: string; onClose: () => void }) {
  const query = useCachedQuery<{ items: DialoguePilot[] }>(`/generation/pilots?project_id=${projectId}`);
  const pilot = query.data?.items[0];
  return <main className="studio-page">
    <header className="studio-header"><button className="back-button" type="button" onClick={onClose}>← Dashboard</button><strong>Private dialogue pilot</strong><span>Review only · publishing disabled</span></header>
    <div className="story-form">{pilot ? <DialoguePilotReview pilotId={pilot.id} /> : <p role="status">{query.error || "Loading pilot…"}</p>}</div>
  </main>;
}
