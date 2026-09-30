"use client";

import { useEffect, useRef, useState } from "react";
import { apiRequest } from "@/lib/api-client";

type AudioJob = { id: string; status: string; reference_id?: string; error?: string };
type Props = {
  projectId: string;
  disabled: boolean;
  onBusy: (busy: boolean) => void;
  onPrepare: () => Promise<void>;
  onComplete: () => Promise<void>;
};

const voices = [
  { id: "83c19893c4974594839bd2d101b1fd66", name: "Female storyteller" },
  { id: "dcd006182803481390993aa6e9669207", name: "Original storyteller" },
];

export function AudioPanel({ projectId, disabled, onBusy, onPrepare, onComplete }: Props) {
  const [reference, setReference] = useState(voices[0].id);
  const [custom, setCustom] = useState("");
  const [job, setJob] = useState<AudioJob | null>(null);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [pollVersion, setPollVersion] = useState(0);
  const requestId = useRef<string | null>(null);
  const submittingRef = useRef(false);
  const callbacks = useRef({ onBusy, onComplete });
  useEffect(() => { callbacks.current = { onBusy, onComplete }; }, [onBusy, onComplete]);
  const busy = submitting || job?.status === "queued" || job?.status === "processing";
  const voice = reference === "custom" ? custom.trim() : reference;

  useEffect(() => {
    let alive = true;
    let timer: ReturnType<typeof setTimeout>;
    let previousId = "";
    let wasActive = false;
    const poll = async () => {
      try {
        const current = await apiRequest<AudioJob | null>(`/generation/project/${projectId}/audio`);
        if (!alive) return;
        setJob(current);
        const active = current?.status === "queued" || current?.status === "processing";
        if (current?.status === "completed" && (wasActive || current.id !== previousId)) {
          callbacks.current.onBusy(true);
          await callbacks.current.onComplete();
        } else {
          callbacks.current.onBusy(active || submittingRef.current);
        }
        previousId = current?.id ?? "";
        wasActive = active;
        if (current?.status === "failed") setError(current.error || "Voice replacement failed");
      } catch (reason) {
        if (alive) {
          setError(reason instanceof Error ? reason.message : "Unable to check audio");
          callbacks.current.onBusy(wasActive || submittingRef.current);
        }
      }
      if (alive && (wasActive || submittingRef.current)) timer = setTimeout(() => void poll(), 3000);
    };
    void poll();
    return () => { alive = false; clearTimeout(timer); };
  }, [projectId, pollVersion]);

  const generate = async () => {
    if (!window.confirm("Generate replacement narration using Fish Audio credits? Existing footage is retained; captions are retimed without changing text or style. The result stays private until Export. Do not edit in another tab while processing.")) return;
    setSubmitting(true);
    submittingRef.current = true;
    onBusy(true);
    setError("");
    try {
      await onPrepare();
      requestId.current ??= crypto.randomUUID();
      const value = await apiRequest<AudioJob>(`/generation/project/${projectId}/audio`, {
        method: "POST", body: { request_id: requestId.current, reference_id: voice, paid_confirmed: true },
      });
      setJob(value);
      setPollVersion((value) => value + 1);
      requestId.current = null;
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Voice replacement failed");
      onBusy(false);
      setPollVersion((value) => value + 1);
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  return (
    <aside className="audio-panel">
      <div className="editor-panel-title"><h2>Storyteller voice</h2></div>
      <div className="audio-controls">
        <p>Replace narration only. Your generated footage stays unchanged.</p>
        <label>Voice<select disabled={busy || disabled} onChange={(event) => { setReference(event.target.value); requestId.current = null; }} value={reference}>
          {voices.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
          <option value="custom">Custom Fish voice</option>
        </select></label>
        {reference === "custom" ? <label>Fish reference ID<input disabled={busy || disabled} maxLength={32} onChange={(event) => { setCustom(event.target.value); requestId.current = null; }} placeholder="32-character voice reference" value={custom} /></label> : null}
        <button disabled={busy || disabled || !/^[a-f\d]{32}$/i.test(voice)} onClick={() => void generate()} type="button">{busy ? "Replacing narration…" : "Generate replacement voice"}</button>
        <p>Uses Fish Audio credits, not video-generation credits. Caption text and styling are preserved. Timing adjusts to the new voice.</p>
        {disabled ? <p>Available for completed narrated episodes.</p> : null}
        {job ? <p role="status">Audio: {job.status}</p> : null}
        {job?.status === "completed" ? <p>Replacement ready. Play the preview, then Export to publish it.</p> : null}
        {error ? <p className="audio-error" role="alert">{error}</p> : null}
        {job?.status === "processing" ? <p>If the worker stops, check its logs before retrying. Paid requests are never automatically repeated.</p> : null}
      </div>
    </aside>
  );
}
