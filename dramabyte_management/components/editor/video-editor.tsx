"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { ArrowLeft, Download, Pause, Play, Redo2, Undo2, Volume2, VolumeX } from "lucide-react";
import { CaptionPanel } from "@/components/editor/caption-panel";
import { EditorAudioPanel } from "@/components/editor/editor-audio-panel";
import { EditorTimeline } from "@/components/editor/editor-timeline";
import { EditorToolbar } from "@/components/editor/editor-toolbar";
import { EditorThemeButton, useEditorTheme } from "@/components/editor/editor-theme";
import { OverlayPanel } from "@/components/editor/overlay-panel";
import { OptionsPanel } from "@/components/editor/options-panel";
import type { BackgroundMusic, Caption, CaptionStyle, EditorOverlay, EditorState, SoundEffect } from "@/components/editor/editor-types";
import { StylePanel } from "@/components/editor/style-panel";
import { VideoCanvas, type VideoCanvasHandle } from "@/components/editor/video-canvas";
import { apiRequest } from "@/lib/api-client";
import type { GenerationResult, StoryProject } from "@/lib/project-types";
import type { HindiTrack } from "@/components/editor/language-panel";
import { loadGeneration } from "@/lib/generation-cache";
import { cachedData, setQuery } from "@/lib/query-cache";
import { changeProject } from "@/lib/project-cache";

type Props = { project: StoryProject; onClose: () => void };
const defaultStyle: CaptionStyle = {
  animation: "none",
  font: "Poppins", size: 54, weight: "700", align: "center", color: "#ffffff",
  background: "#111111", background_opacity: .82, x: .5, y: .82, max_width: .82,
  template: "classic", italic: false, underline: false, outline: 0,
  outline_color: "#000000", shadow: 0, letter_spacing: 0,
};

export function VideoEditor({ project, onClose }: Props) {
  const theme = useEditorTheme();
  const canvas = useRef<VideoCanvasHandle>(null);
  const hydrated = useRef(false);
  const [result, setResult] = useState<GenerationResult>();
  const [captions, setCaptions] = useState<Caption[]>([]);
  const [style, setStyle] = useState(defaultStyle);
  const [overlays, setOverlays] = useState<EditorOverlay[]>([]);
  const [effects, setEffects] = useState<SoundEffect[]>([]);
  const [selectedOverlayId, setSelectedOverlayId] = useState<string | null>(null);
  const [music, setMusic] = useState<BackgroundMusic | null>(null);
  const [duration, setDuration] = useState(0);
  const [time, setTime] = useState(0);
  const [playing, setPlaying] = useState(false);
  const [muted, setMuted] = useState(false);
  const [volume, setVolume] = useState(1);
  const [saving, setSaving] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [audioBusy, setAudioBusy] = useState(false);
  const [audioLanguage, setAudioLanguage] = useState<"en" | "hi">("en");
  const [error, setError] = useState("");
  const [tool, setTool] = useState("Captions");
  const selectedOverlay = overlays.find((item) => item.id === selectedOverlayId);
  const activeStyle = selectedOverlay?.style ?? style;
  const saveEditor = useCallback(async () => {
    const state: EditorState = { captions, style, music, overlays, sound_effects: effects };
    await apiRequest(`/generation/project/${project.id}/editor`, { method: "PATCH", body: state });
    const key = `/generation/project/${project.id}`;
    const cached = cachedData<GenerationResult>(key);
    if (cached) setQuery(key, { ...cached, editor: state });
  }, [captions, style, music, overlays, effects, project.id]);

  useEffect(() => {
    void loadGeneration(project.id).then((value) => {
      setResult(value);
      if (value.editor) {
        setCaptions(value.editor.captions);
        setStyle({ ...defaultStyle, ...value.editor.style });
        setMusic(value.editor.music ?? null);
        setOverlays(value.editor.overlays ?? []);
        setEffects(value.editor.sound_effects ?? []);
      }
      hydrated.current = true;
    }).catch((reason: Error) => setError(reason.message));
  }, [project.id]);

  useEffect(() => {
    if (!hydrated.current || audioBusy) return;
    setSaving(true);
    const timer = window.setTimeout(() => {
      void saveEditor().then(() => setSaving(false)).catch((reason: Error) => {
        setSaving(false);
        setError(reason.message);
      });
    }, 500);
    return () => window.clearTimeout(timer);
  }, [saveEditor, audioBusy]);
  const refreshAudio = async () => {
    const value = await loadGeneration(project.id, true);
    setResult(value);
    if (value.editor) {
      setCaptions(value.editor.captions);
      setStyle({ ...defaultStyle, ...value.editor.style });
      setMusic(value.editor.music ?? null);
    }
    canvas.current?.seek(0);
    setTime(0);
    setPlaying(false);
    setAudioBusy(false);
  };
  const seek = (value: number) => { canvas.current?.seek(value); setTime(value); };
  const hindiCaptions = (result?.localization?.captions ?? []) as Caption[];
  const previewCaptions = audioLanguage === "hi" && hindiCaptions.length ? hindiCaptions : captions;
  const active = previewCaptions.find((item) => time >= item.start && time < item.end);
  const patchStyle = (value: CaptionStyle) => selectedOverlay
    ? setOverlays((items) => items.map((item) => item.id === selectedOverlay.id ? { ...item, style: value } : item))
    : setStyle(value);
  const addText = () => {
    const item: EditorOverlay = {
      id: crypto.randomUUID(), kind: "text", text: "Your text", asset_key: "", image_url: "",
      x: .5, y: .5, width: .75, height: .18, opacity: 1, start: time, end: Math.min(duration || 5, time + 5),
      style: { ...defaultStyle, background_opacity: 0 },
    };
    setOverlays((items) => [...items, item]);
    setSelectedOverlayId(item.id);
  };
  const uploadImage = async (file: File) => {
    const form = new FormData();
    form.set("file", file);
    const asset = await apiRequest<{ asset_key: string; image_url: string }>(
      `/generation/project/${project.id}/assets/image`, { method: "POST", body: form },
    );
    const item: EditorOverlay = {
      id: crypto.randomUUID(), kind: "image", text: "", ...asset,
      x: .5, y: .5, width: .45, height: .3, opacity: 1, start: time,
      end: Math.min(duration || 5, time + 5), style: { ...defaultStyle },
    };
    setOverlays((items) => [...items, item]);
    setSelectedOverlayId(item.id);
  };
  const exportVideo = async () => {
    setExporting(true);
    setError("");
    try {
      await saveEditor();
      await apiRequest(`/generation/project/${project.id}/export`, { method: "POST", body: { captions, style, music, overlays, sound_effects: effects } });
      const updated = await waitForExport(project.id);
      setResult(updated);
      setQuery(`/generation/project/${project.id}`, updated);
      changeProject(project.id, { status: "published", progress: 100 });
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Export failed");
    } finally {
      setExporting(false);
    }
  };
  const changeEffect = (id: string, patch: Partial<SoundEffect>) =>
    setEffects((items) => items.map((item) => item.track_id === id ? { ...item, ...patch } : item));
  const source = result?.preview_url;

  return <main className="video-editor" data-theme={theme.theme}>
    <header className="editor-header">
      <button onClick={onClose} type="button"><ArrowLeft size={17} /> Dashboard</button><strong>{project.title}</strong>
      <div><span>{saving ? "Saving changes…" : project.production_mode === "dialogue_pilot" ? "Private review editor" : result?.status === "published" ? "Published · edits stay on original" : "Production editor"}</span><EditorThemeButton onClick={theme.toggle} theme={theme.theme} /><button disabled type="button"><Undo2 size={17} /></button><button disabled type="button"><Redo2 size={17} /></button><button className="export-button" disabled={audioBusy || project.production_mode === "dialogue_pilot" || exporting || !source} onClick={() => void exportVideo()} type="button"><Download size={17} />{project.production_mode === "dialogue_pilot" ? "Private pilot" : exporting ? "Exporting…" : "Export"}</button></div>
    </header>
    <section className="editor-workspace">
      <EditorToolbar active={tool} onSelect={setTool} />
      <div className="editor-side-panel" inert={audioBusy && tool !== "Audio"}>
        {tool === "Audio" ? <EditorAudioPanel currentTime={time} disabled={exporting || !source} localization={result?.localization as HindiTrack | null} selectedLanguage={audioLanguage} onLanguageChange={setAudioLanguage} music={music} onBusy={setAudioBusy} onComplete={refreshAudio} onMusicChange={setMusic} onPrepare={saveEditor} onSoundEffectsChange={setEffects} projectId={project.id} soundEffects={effects} /> : null}
        {tool === "Captions" ? <CaptionPanel activeId={active?.id ?? 0} captions={captions} onAdd={() => setCaptions((items) => [...items, { id: Math.max(-1, ...items.map((item) => item.id)) + 1, text: "New caption", start: time, end: Math.min(duration || 5, time + 2) }])} onChange={(id, text) => setCaptions((items) => items.map((item) => item.id === id ? { ...item, text } : item))} onSelect={(item) => seek(item.start)} onTiming={(id, start, end) => setCaptions((items) => items.map((item) => item.id === id ? { ...item, start: Math.max(0, start), end: Math.max(start + .1, end) } : item))} /> : null}
        {tool === "Text" || tool === "Media" ? <OverlayPanel mode={tool} onAddText={addText} onRemove={(id) => { setOverlays((items) => items.filter((item) => item.id !== id)); setSelectedOverlayId(null); }} onSelect={setSelectedOverlayId} onUpdate={(id, patch) => setOverlays((items) => items.map((item) => item.id === id ? { ...item, ...patch } : item))} onUpload={uploadImage} overlays={overlays} selectedId={selectedOverlayId} /> : null}
        {tool === "Options" ? <OptionsPanel duration={duration} aspect={project.aspect_ratio} /> : null}
      </div>
      <div className="editor-canvas">{source ? <VideoCanvas caption={active} currentTime={time} music={music} narrationUrl={audioLanguage === "hi" ? result?.localization?.audio_url : null} onDuration={setDuration} onOverlayChange={(id, patch) => setOverlays((items) => items.map((item) => item.id === id ? { ...item, ...patch } : item))} onOverlaySelect={setSelectedOverlayId} onPlaying={setPlaying} onStyleChange={patchStyle} onTime={setTime} overlays={overlays} ref={canvas} selectedOverlayId={selectedOverlayId} soundEffects={effects} style={style} url={source} /> : <p>{error || "Preparing clean production master…"}</p>}</div>
      <StylePanel onChange={patchStyle} style={activeStyle} />
    </section>
    <footer className="editor-footer">
      <div className="playback"><button onClick={() => void canvas.current?.toggle()} type="button">{playing ? <Pause size={17} /> : <Play size={17} fill="currentColor" />}</button><strong>{formatTime(time)}</strong><span>/ {formatTime(duration)}</span><button aria-label={muted ? "Unmute" : "Mute"} onClick={() => { setMuted(!muted); canvas.current?.mute(!muted); }} type="button">{muted ? <VolumeX size={16} /> : <Volume2 size={16} />}</button><input aria-label="Volume" max="1" min="0" onChange={(event) => { setVolume(Number(event.target.value)); canvas.current?.volume(Number(event.target.value)); }} step="0.05" type="range" value={muted ? 0 : volume} />{result?.published_url ? <a className="published-link" href={result.published_url} rel="noreferrer" target="_blank">Open published video</a> : null}</div>
      <EditorTimeline captions={captions} currentTime={time} duration={duration} effects={effects} music={music} onCaptionChange={(id, start, end) => setCaptions((items) => items.map((item) => item.id === id ? { ...item, start, end } : item))} onEffectChange={changeEffect} onOverlayChange={(id, patch) => setOverlays((items) => items.map((item) => item.id === id ? { ...item, ...patch } : item))} onOverlaySelect={setSelectedOverlayId} onSeek={seek} overlays={overlays} projectId={project.id} source={source} />
    </footer>
  </main>;
}

async function waitForExport(id: string) {
  for (let attempt = 0; attempt < 120; attempt += 1) {
    await new Promise((resolve) => window.setTimeout(resolve, 2000));
    const value = await loadGeneration(id, true);
    if (value.status === "published" && value.published_url) return value;
    if (value.status === "failed") throw new Error(value.error || "Export failed");
  }
  throw new Error("Export is still processing. You can safely return later.");
}

const formatTime = (seconds: number) => !Number.isFinite(seconds) ? "0:00" : `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, "0")}`;
