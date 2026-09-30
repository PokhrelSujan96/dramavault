"use client";

import { useEffect, useRef, useState } from "react";
import { apiRequest } from "@/lib/api-client";

type Voice = { id: string; name: string };
export type HindiTrack = {
  status: string;
  error?: string | null;
  voice_id?: string;
  audio_url?: string | null;
  captions?: { id: number; text: string; start: number; end: number }[];
  translated_script?: string;
};
type Job = HindiTrack & { id: string; language?: string };
type Props = {
  projectId: string;
  disabled: boolean;
  selectedLanguage: string;
  track?: HindiTrack | null;
  onBusy: (busy: boolean) => void;
  onComplete: () => Promise<void>;
  onSelect: (language: "en" | "hi") => void;
};

export function LanguagePanel(props: Props) {
  const [voices, setVoices] = useState<Voice[]>([]);
  const [voiceId, setVoiceId] = useState("");
  const [job, setJob] = useState<Job | null>(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [pollVersion, setPollVersion] = useState(0);
  const requestId = useRef<string | null>(null);
  const callbacks = useRef(props);
  useEffect(() => { callbacks.current = props; }, [props]);

  useEffect(() => {
    let active = true;
    void apiRequest<Voice[]>("/generation/voices")
      .then((items) => {
        if (!active) return;
        setVoices(items);
        setVoiceId((current) => items.some((item) => item.id === current)
          ? current
          : items.find((item) => item.id === props.track?.voice_id)?.id || items[0]?.id || "");
      })
      .catch((reason: Error) => { if (active) setError(reason.message); });
    return () => { active = false; };
  }, [props.projectId, props.track?.voice_id]);

  useEffect(() => {
    let alive = true;
    let timer: ReturnType<typeof setTimeout>;
    let previousId = "";
    let wasActive = false;
    const poll = async () => {
      try {
        const current = await apiRequest<Job | null>(
          `/generation/project/${props.projectId}/languages/hi`,
        );
        if (!alive) return;
        setJob(current);
        if (current?.voice_id && voices.some((voice) => voice.id === current.voice_id)) {
          setVoiceId(current.voice_id);
        }
        const running = current?.status === "queued" || current?.status === "processing";
        callbacks.current.onBusy(running);
        const savedTrackLoaded = Boolean(callbacks.current.track?.audio_url);
        if (
          current?.status === "completed" &&
          (wasActive ||
            (previousId === "" && current.id !== "" && !savedTrackLoaded))
        ) {
          await callbacks.current.onComplete();
          if (wasActive) callbacks.current.onSelect("hi");
        }
        if (current?.status === "failed") setError(current.error || "Hindi audio generation failed");
        wasActive = running;
        previousId = current?.id ?? "";
        if (running) timer = setTimeout(() => void poll(), 2500);
      } catch (reason) {
        if (alive) setError(reason instanceof Error ? reason.message : "Unable to load language status");
      }
    };
    void poll();
    return () => { alive = false; clearTimeout(timer); };
  }, [props.projectId, pollVersion, voices]);

  const track = job?.status === "completed" ? job : props.track;
  const running = busy || job?.status === "queued" || job?.status === "processing";
  const reusingTranslation = Boolean(job?.translated_script || track?.translated_script);

  const create = async () => {
    const resumeSaved = job?.status === "failed" && Boolean(job.audio_url) && job.voice_id === voiceId;
    const changingVoice = Boolean(track?.audio_url && track.voice_id !== voiceId);
    const confirmation = resumeSaved
      ? "Resume Hindi caption alignment using the audio already saved in R2? This will not call Fish Audio again."
      : changingVoice
        ? "Generate Hindi narration with the selected Fish Audio voice? The saved Hindi translation is reused. Fish S2.1 Pro is currently available through its free API tier."
        : reusingTranslation
          ? "Use the Hindi translation already saved for this episode and generate audio with Fish S2.1 Pro? This will not translate again."
          : "Translate this narration with DeepSeek and create Hindi audio using Fish S2.1 Pro? This may use DeepSeek credits; Fish API usage is currently free subject to its fair-use policy.";
    if (!window.confirm(confirmation)) return;
    setBusy(true);
    props.onBusy(true);
    setError("");
    try {
      requestId.current ??= crypto.randomUUID();
      const value = await apiRequest<Job>(
        `/generation/project/${props.projectId}/languages/hi`,
        { method: "POST", body: { request_id: requestId.current, voice_id: voiceId, paid_confirmed: true } },
      );
      requestId.current = null;
      setJob(value);
      setPollVersion((version) => version + 1);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Unable to start Hindi audio");
      props.onBusy(false);
    } finally {
      setBusy(false);
    }
  };

  return <aside className="audio-panel">
    <div className="editor-panel-title"><h2>Video languages</h2></div>
    <div className="audio-controls">
      <p>Keep the original English audio and add a Hindi narration track using Fish Audio S2.1 Pro.</p>
      <label>Preview language<select disabled={!track || props.disabled} onChange={(event) => props.onSelect(event.target.value as "en" | "hi")} value={props.selectedLanguage}>
        <option value="en">English · Original</option>
        {track ? <option value="hi">हिन्दी · Dubbed</option> : null}
      </select></label>
      {track?.audio_url || (job?.status === "failed" && job.audio_url) ? <audio controls preload="none" src={track?.audio_url ?? job?.audio_url ?? undefined} /> : null}
      <label>Hindi voice<select disabled={running || props.disabled || voices.length === 0} onChange={(event) => setVoiceId(event.target.value)} value={voiceId}>
          {voices.map((voice) => <option key={voice.id} value={voice.id}>{voice.name}</option>)}
      </select></label>
      {(!track || track.voice_id !== voiceId || (job?.status === "failed" && job.audio_url && job.voice_id === voiceId)) ? <button disabled={running || props.disabled || !voiceId} onClick={() => void create()} type="button">
          {running ? "Creating Hindi track…" : job?.status === "failed" && job.audio_url && job.voice_id === voiceId ? "Resume saved Hindi audio" : track ? "Create selected Hindi voice" : reusingTranslation ? "Create Hindi audio from saved translation" : "Translate and create Hindi audio"}
      </button> : null}
      {track && track.voice_id === voiceId ? <p role="status">Hindi narration is saved. Language switching does not call providers again.</p> : null}
      <p>Use Export after creating the track to publish an English and Hindi video version.</p>
      <p>Fish free access is subject to fair use and may have commercial-use restrictions.</p>
      {job?.status === "queued" || job?.status === "processing" ? <p>Translation and narration run once in the background; keep the editor open or return later.</p> : null}
      {error ? <p className="audio-error" role="alert">{error}</p> : null}
    </div>
  </aside>;
}
