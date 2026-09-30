import { useEffect, useState } from "react";
import { apiRequest } from "@/lib/api-client";
import { useCachedQuery } from "@/hooks/use-cached-query";
import type { HybridState } from "./hybrid-types";
import { ShotDirection } from "./shot-direction";

type Props = { projectId: string; refreshKey: number; onQueued: () => void };
type SeriesList = { items: { id: string; title: string }[] };

export function HybridProduction({ projectId, refreshKey, onQueued }: Props) {
  const query = useCachedQuery<HybridState>(`/generation/project/${projectId}/hybrid`);
  const series = useCachedQuery<SeriesList>("/admin/series");
  const [seriesId, setSeriesId] = useState("");
  const [episode, setEpisode] = useState(1);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const data = query.data;
  const reload = query.reload;
  useEffect(() => { if (refreshKey > 0) void reload(); }, [refreshKey, reload]);

  useEffect(() => {
    if (!data || !["queued", "generating"].includes(data.project_status)) return;
    const timer = window.setInterval(() => { void reload(); }, 10000);
    return () => window.clearInterval(timer);
  }, [reload, data]);

  async function action(path: string, method: string, body?: unknown) {
    setBusy(true); setError("");
    try {
      await apiRequest(path, { method, body });
      await query.reload();
    } catch (cause) { setError(cause instanceof Error ? cause.message : "Action failed"); }
    finally { setBusy(false); }
  }

  async function continueProduction() {
    if (data?.run?.state !== "motion_review" && !window.confirm(`Generate ${data?.shots.filter((shot) => shot.kind === "motion").length ?? 0} motion clips? This uses paid Fal credits.`)) return;
    setBusy(true); setError("");
    try {
      await apiRequest("/generation/start", { method: "POST", body: { project_id: projectId }, idempotencyKey: crypto.randomUUID() });
      onQueued();
      await query.reload();
    } catch (cause) { setError(cause instanceof Error ? cause.message : "Unable to resume"); }
    finally { setBusy(false); }
  }

  return <section className="hybrid-production">
    <h3>Story-aligned motion · 480p → 1080p</h3>
    <p>Every final shot uses video footage. Keyframes are only generation inputs. Narration and captions share local Whisper word timestamps. Approve the location, action, visible details and character identity before spending motion credits.</p>
    {(error || query.error) && <p role="alert" className="dashboard-error">{error || query.error}</p>}
    {data?.project_status === "failed" && <p role="alert" className="dashboard-error">Production failed{data.error ? `: ${data.error}` : ""}. Fix the cause and start production again; saved narration and paid assets are reused.</p>}
    {!data?.series_id ? <div className="hybrid-assignment">
      <label>Series<select value={seriesId} onChange={(event) => setSeriesId(event.target.value)}><option value="">Choose a series</option>{series.data?.items.map((item) => <option key={item.id} value={item.id}>{item.title}</option>)}</select></label>
      <label>Episode number<input type="number" min={1} max={100000} value={episode} onChange={(event) => setEpisode(Number(event.target.value))} /></label>
      <button type="button" disabled={busy || !seriesId} onClick={() => void action(`/admin/series/${seriesId}/episodes`, "POST", { project_id: projectId, episode_number: episode })}>Assign draft to series</button>
    </div> : <p>Episode {data.episode_number} · Cast: {data.characters.map((character) => character.name).join(", ") || "Add character portraits in Series management first"}</p>}
    {data?.shots.length ? <>
      <p>{data.shots.length} shots · {data.run?.duration_seconds?.toFixed(1)} seconds · {data.shots.filter((shot) => shot.approved).length} approved</p>
      <div className="hybrid-shot-grid">{data.shots.map((shot) => <article key={shot.id}>
        {shot.video_url ? <video controls preload="metadata" src={shot.video_url} /> : shot.image_url ? <img src={shot.image_url} alt={`Shot ${shot.shot_index + 1}`} /> : <div className="hybrid-image-placeholder">Keyframe pending</div>}
        <strong>Shot {shot.shot_index + 1} · video footage</strong><p>{shot.narration}</p><ShotDirection shot={shot} />
        <div className="management-actions"><button type="button" disabled={busy || !shot.image_url || data.run?.state !== "review"} onClick={() => void action(`/generation/project/${projectId}/shots/${shot.id}/approval`, "PATCH", { approved: !shot.approved })}>{shot.approved ? "Story & identity approved ✓" : "Approve story & identity"}</button>
          <button type="button" disabled={busy || data.run?.state === "ready"} onClick={() => { if (window.confirm("Discard this keyframe and motion asset? The next production run will generate replacements using paid credits.")) void action(`/generation/project/${projectId}/shots/${shot.id}/reroll`, "POST"); }}>Reroll</button></div>
        {shot.video_url && <button type="button" disabled={busy || data.run?.state !== "motion_review"} onClick={() => void action(`/generation/project/${projectId}/shots/${shot.id}/motion-approval`, "PATCH", { approved: !shot.motion_approved })}>{shot.motion_approved ? "Motion approved ✓" : "Approve motion quality"}</button>}
      </article>)}</div>
      {data.run?.state === "review" && <button type="button" disabled={busy || !data.shots.every((shot) => shot.approved)} onClick={() => void continueProduction()}>Generate all approved video shots</button>}
      {data.run?.state === "motion_review" && <button type="button" disabled={busy || !data.shots.filter((shot) => shot.kind === "motion").every((shot) => shot.motion_approved)} onClick={() => void continueProduction()}>Finish approved episode · local 1080p render</button>}
    </> : null}
  </section>;
}
