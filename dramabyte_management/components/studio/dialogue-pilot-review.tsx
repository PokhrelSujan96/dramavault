import { useEffect, useState } from "react";
import { apiRequest } from "@/lib/api-client";
import { useCachedQuery } from "@/hooks/use-cached-query";
import type { DialoguePilot } from "./dialogue-types";

export function DialoguePilotReview({ pilotId }: { pilotId: string }) {
  const query = useCachedQuery<DialoguePilot>(`/generation/pilots/${pilotId}`);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const data = query.data;
  const reload = query.reload;
  useEffect(() => {
    if (!data || !["queued", "voices", "video"].includes(data.state)) return;
    const timer = window.setInterval(() => { void reload(); }, 10000);
    return () => window.clearInterval(timer);
  }, [data, reload]);

  async function action(path: string, method: string, body: unknown) {
    setBusy(true); setError("");
    try { await apiRequest(path, { method, body }); await reload(); }
    catch (cause) { setError(cause instanceof Error ? cause.message : "Pilot action failed"); }
    finally { setBusy(false); }
  }

  async function start() {
    if (!data) return;
    if (data.state !== "motion_review" && !window.confirm(`Start paid pilot production within a $${(data.budget_cents / 100).toFixed(2)} estimated allowance? Provider invoices may differ. This remains private.`)) return;
    await action(`/generation/pilots/${pilotId}/start`, "POST", { paid_confirmed: true });
  }

  const approve = (name: string) => action(`/generation/pilots/${pilotId}/approvals/${name}`, "PATCH", { approved: !data?.approvals[name] });
  if (!data) return <p role="status">{query.error || "Loading pilot draft…"}</p>;
  const imagesApproved = data.approvals.location && data.plan.shots.every((shot) => data.approvals[`image-${shot.index}`]);
  const clipsApproved = data.plan.shots.every((shot) => data.approvals[`clip-${shot.index}`]);
  const canStart = ["draft", "failed"].includes(data.state) || (data.state === "review" && imagesApproved) || (data.state === "motion_review" && clipsApproved);
  return <section className="hybrid-production">
    <h3>{data.plan.title}</h3>
    <p>Private · {data.state.replaceAll("_", " ")} · {data.plan.shots.length} shots · {data.plan.shots.reduce((sum, shot) => sum + shot.seconds, 0).toFixed(1)}s planned</p>
    <p>Reserved request allowances: ${(data.reserved_cents / 100).toFixed(2)} / ${(data.budget_cents / 100).toFixed(2)}. Estimates are not billing receipts. No automatic rerolls.</p>
    <details><summary>Shared set and continuity</summary><p>{data.plan.location}</p><p>{data.plan.continuity}</p></details>
    {(error || data.error_message) && <p role="alert" className="dashboard-error">{error || data.error_message}</p>}
    {data.asset_urls.master && <video controls preload="metadata" src={data.asset_urls.master} />}
    {data.asset_urls.location && <article><img src={data.asset_urls.location} alt="Shared train carriage set" /><button type="button" disabled={busy || data.state !== "review"} onClick={() => void approve("location")}>{data.approvals.location ? "Set approved ✓" : "Approve shared set"}</button></article>}
    <div className="hybrid-shot-grid">{data.plan.shots.map((shot) => {
      const image = `image-${shot.index}`;
      const clip = `clip-${shot.index}`;
      const media = data.asset_urls[shot.role === "dialogue" ? `lipsync-${shot.index}` : `motion-${shot.index}`];
      const speaker = data.cast_snapshot.find((person) => person.id === shot.speaker_id);
      return <article key={shot.index}>
        {media ? <video controls preload="metadata" src={media} /> : data.asset_urls[image] ? <img src={data.asset_urls[image]} alt={`Shot ${shot.index + 1}`} /> : <div className="hybrid-image-placeholder">Keyframe not generated</div>}
        <strong>{shot.index + 1} · {shot.role} · {shot.seconds.toFixed(2)}s</strong>
        {shot.text && <p>{speaker?.name}: “{shot.text}”</p>}
        <p>{shot.action}</p><small>{shot.camera}</small>
        {data.asset_urls[`dialogue-${shot.index}`] && <audio controls preload="none" src={data.asset_urls[`dialogue-${shot.index}`]} />}
        {data.state === "review" && <button type="button" disabled={busy || !data.asset_urls[image]} onClick={() => void approve(image)}>{data.approvals[image] ? "Story & identity approved ✓" : "Approve keyframe and voice"}</button>}
        {data.state === "motion_review" && <button type="button" disabled={busy || !media} onClick={() => void approve(clip)}>{data.approvals[clip] ? "Performance approved ✓" : "Approve performance & lip-sync"}</button>}
      </article>;
    })}</div>
    {!data.paid_generation_enabled && <p>Build-only mode: paid generation is disabled on the server. No credits will be spent.</p>}
    {data.state !== "ready" && <button type="button" disabled={busy || !canStart || !data.paid_generation_enabled} onClick={() => void start()}>{data.state === "motion_review" ? "Finish private pilot · local render" : data.state === "review" ? "Generate approved footage & lip-sync · paid" : "Start pilot · paid confirmation required"}</button>}
    <p>Shared procedural train ambience is mixed below dialogue. Premium music and recorded effects are not included. Publishing is disabled for pilot projects.</p>
  </section>;
}
