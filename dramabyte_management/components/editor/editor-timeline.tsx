import { useRef, type CSSProperties, type PointerEvent } from "react";
import { AudioWaveform } from "@/components/editor/audio-waveform";
import type { BackgroundMusic, Caption, EditorOverlay, SoundEffect } from "@/components/editor/editor-types";

type Props = {
  captions: Caption[];
  overlays: EditorOverlay[];
  effects: SoundEffect[];
  currentTime: number;
  duration: number;
  projectId: string;
  source?: string;
  music: BackgroundMusic | null;
  onSeek: (time: number) => void;
  onEffectChange: (id: string, patch: Partial<SoundEffect>) => void;
  onCaptionChange: (id: number, start: number, end: number) => void;
  onOverlayChange: (id: string, patch: Partial<EditorOverlay>) => void;
  onOverlaySelect: (id: string) => void;
};

type ClipProps = {
  start: number;
  end: number;
  duration: number;
  label: string;
  active: boolean;
  onSeek: (time: number) => void;
  onDrag: (
    mode: "move" | "start" | "end",
    delta: number,
    originStart: number,
    originEnd: number,
  ) => void;
};

function Clip({ start, end, duration, label, active, onSeek, onDrag }: ClipProps) {
  const drag = useRef<{
    x: number;
    width: number;
    mode: "move" | "start" | "end";
    originStart: number;
    originEnd: number;
  } | null>(null);
  const begin = (event: PointerEvent<HTMLElement>, mode: "move" | "start" | "end") => {
    event.stopPropagation();
    event.currentTarget.setPointerCapture(event.pointerId);
    const track = event.currentTarget.closest(".timeline-lane");
    if (!track) return;
    drag.current = {
      x: event.clientX,
      width: track.getBoundingClientRect().width,
      mode,
      originStart: start,
      originEnd: end,
    };
    if (mode === "move") onSeek(start);
  };
  const move = (event: PointerEvent<HTMLElement>) => {
    if (!drag.current) return;
    onDrag(
      drag.current.mode,
      (event.clientX - drag.current.x) / drag.current.width * duration,
      drag.current.originStart,
      drag.current.originEnd,
    );
  };
  return <div className={active ? "timeline-clip active" : "timeline-clip"} onPointerDown={(event) => begin(event, "move")} onPointerMove={move} onPointerUp={() => { drag.current = null; }} style={{ left: `${start / duration * 100}%`, width: `${Math.max(.8, (end - start) / duration * 100)}%` }} title={label}>
    <span className="clip-handle" onPointerDown={(event) => begin(event, "start")} onPointerMove={move} onPointerUp={() => { drag.current = null; }} />
    <span>{label}</span>
    <span className="clip-handle end" onPointerDown={(event) => begin(event, "end")} onPointerMove={move} onPointerUp={() => { drag.current = null; }} />
  </div>;
}

export function EditorTimeline({ captions, overlays, effects, currentTime, duration, projectId, source, music, onSeek, onCaptionChange, onEffectChange, onOverlayChange, onOverlaySelect }: Props) {
  const total = Math.max(1, duration);
  const progress = Math.min(100, currentTime / total * 100);
  const size = { "--timeline-width": `${Math.max(980, total * 48)}px` } as CSSProperties;
  const seekAt = (event: PointerEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    onSeek(Math.max(0, Math.min(total, (event.clientX - rect.left) / rect.width * total)));
  };
  return <section aria-label="Episode timeline" className="editor-timeline" style={size}>
    <div className="timeline-ruler"><span>Captions</span><div className="timeline-lane" onPointerDown={seekAt}>
      {captions.map((item) => <Clip key={item.id} active={false} duration={total} end={item.end} label={item.text} onDrag={(mode, delta, originStart, originEnd) => {
        const start = mode === "start" ? Math.max(0, Math.min(originEnd - .1, originStart + delta)) : mode === "move" ? Math.max(0, Math.min(total - (originEnd - originStart), originStart + delta)) : originStart;
        const end = mode === "end" ? Math.max(originStart + .1, Math.min(total, originEnd + delta)) : mode === "move" ? start + originEnd - originStart : originEnd;
        onCaptionChange(item.id, start, end);
      }} onSeek={onSeek} start={item.start} />)}
      <i className="timeline-playhead" style={{ left: `${progress}%` }} />
    </div></div>
    <Track label="Video" className="video" onSeek={seekAt} progress={progress}><strong>Generated drama master</strong></Track>
    <Track label="Narration" className="audio" onSeek={seekAt} progress={progress}><AudioWaveform projectId={projectId} source={source} /></Track>
    {music ? <Track label="Music" className="music" onSeek={seekAt} progress={progress}><strong>{music.title} · CC {music.license.toUpperCase()}</strong></Track> : null}
    {effects.map((item) => <div className="timeline-track effect" key={item.track_id}><span>Effect</span><div className="timeline-lane">
      <Clip active duration={total} end={item.start + Math.max(.1, item.trim_end - item.trim_start)} label={item.title} onSeek={onSeek} start={item.start} onDrag={(mode, delta, originStart, originEnd) => {
        const trimLength = originEnd - originStart;
        const originTrimStart = item.trim_end - trimLength;
        const originTrimEnd = item.trim_start + trimLength;
        if (mode === "move") onEffectChange(item.track_id, { start: Math.max(0, Math.min(total - trimLength, originStart + delta)) });
        if (mode === "start") { const amount = Math.max(-originTrimStart, Math.min(delta, trimLength - .1)); onEffectChange(item.track_id, { start: Math.max(0, originStart + amount), trim_start: Math.max(0, originTrimStart + amount) }); }
        if (mode === "end") onEffectChange(item.track_id, { trim_end: Math.max(item.trim_start + .1, Math.min(item.duration || total, originTrimEnd + delta)) });
      }} />
      <i className="timeline-playhead" style={{ left: `${progress}%` }} />
    </div></div>)}
    {overlays.map((item) => <div className="timeline-track overlay" key={item.id}><span>{item.kind === "text" ? "Text" : "Image"}</span><div className="timeline-lane">
      <Clip active duration={total} end={item.end} label={item.kind === "text" ? item.text || "Text" : "Image layer"} onSeek={(value) => { onOverlaySelect(item.id); onSeek(value); }} start={item.start} onDrag={(mode, delta, originStart, originEnd) => {
        if (mode === "move") { const start = Math.max(0, Math.min(total - (originEnd - originStart), originStart + delta)); onOverlayChange(item.id, { start, end: start + originEnd - originStart }); }
        if (mode === "start") onOverlayChange(item.id, { start: Math.max(0, Math.min(originEnd - .1, originStart + delta)) });
        if (mode === "end") onOverlayChange(item.id, { end: Math.max(originStart + .1, Math.min(total, originEnd + delta)) });
      }} />
      <i className="timeline-playhead" style={{ left: `${progress}%` }} />
    </div></div>)}
  </section>;
}

function Track({ label, className, onSeek, progress, children }: { label: string; className: string; onSeek: (event: PointerEvent<HTMLDivElement>) => void; progress: number; children: React.ReactNode }) {
  return <div className={`timeline-track ${className}`}><span>{label}</span><div className="timeline-lane" onPointerDown={onSeek}>
    {children}<i className="timeline-playhead" style={{ left: `${progress}%` }} />
  </div></div>;
}
