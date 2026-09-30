"use client";

import { forwardRef, useEffect, useImperativeHandle, useRef } from "react";
import Image from "next/image";
import {
  clamp,
  drawCaption,
  hexColor,
  overlayFade,
  overlayScale,
} from "@/components/editor/caption-canvas";
import type { VideoCanvasHandle, VideoCanvasProps } from "@/components/editor/video-canvas-types";

export type { VideoCanvasHandle } from "@/components/editor/video-canvas-types";

export const VideoCanvas = forwardRef<VideoCanvasHandle, VideoCanvasProps>(function VideoCanvas({ url, narrationUrl, caption, style, music, currentTime, overlays, soundEffects, selectedOverlayId, onOverlayChange, onOverlaySelect, onStyleChange, onDuration, onTime, onPlaying }, ref) {
  const stageRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const musicRef = useRef<HTMLAudioElement>(null);
  const narrationRef = useRef<HTMLAudioElement>(null);
  const userMuted = useRef(false);
  const syncMusic = useRef<() => void>(() => {});
  const effectPlayers = useRef(new Map<string, HTMLAudioElement>());
  const dragRef = useRef<
    | { kind: "caption" }
    | { kind: "overlay"; id: string }
    | { kind: "resize"; id: string; x: number; width: number }
    | null
  >(null);
  const latest = useRef({ caption, style, music, soundEffects, narrationUrl });

  useEffect(() => {
    latest.current = { caption, style, music, soundEffects, narrationUrl };
  }, [caption, style, music, soundEffects, narrationUrl]);

  useEffect(() => {
    const video = videoRef.current;
    const audio = musicRef.current;
    const narration = narrationRef.current;
    if (!video || !audio) return;
    const sync = () => {
      const alternate = narrationRef.current;
      if (alternate && latest.current.narrationUrl) {
        if (video.paused || alternate.readyState < 2) {
          alternate.pause();
        } else {
          if (Math.abs(alternate.currentTime - video.currentTime) > 0.25) {
            alternate.currentTime = video.currentTime;
          }
          alternate.volume = video.volume;
          if (alternate.paused) void alternate.play().catch(() => undefined);
        }
      } else if (alternate) {
        alternate.pause();
      }
      const selected = latest.current.music;
      if (!selected || video.paused) {
        audio.pause();
      } else {
        const elapsed = video.currentTime - selected.start;
        const available = Math.max(0, video.duration - selected.start);
        if (elapsed < 0 || elapsed >= available || audio.readyState < 2) {
          audio.pause();
        } else {
          const trackDuration = selected.duration || available;
          const target = elapsed % trackDuration;
          if (Math.abs(audio.currentTime - target) > 0.35) audio.currentTime = target;
          let level = selected.volume;
          if (selected.fade_in > 0) level *= Math.min(1, elapsed / selected.fade_in);
          const remaining = available - elapsed;
          if (selected.fade_out > 0 && remaining < selected.fade_out) {
            level *= Math.max(0, remaining / selected.fade_out);
          }
          audio.volume = Math.max(0, Math.min(1, level));
          if (audio.paused) void audio.play().catch(() => undefined);
        }
      }
      latest.current.soundEffects.forEach((effect) => {
        const player = effectPlayers.current.get(effect.track_id);
        if (!player) return;
        const elapsed = video.currentTime - effect.start;
        const clipDuration = effect.trim_end - effect.trim_start;
        if (video.paused || elapsed < 0 || elapsed >= clipDuration) {
          player.pause();
          return;
        }
        const target = effect.trim_start + elapsed;
        if (Math.abs(player.currentTime - target) > .2) player.currentTime = target;
        let level = effect.volume;
        if (effect.fade_in > 0) level *= Math.min(1, elapsed / effect.fade_in);
        if (effect.fade_out > 0 && clipDuration - elapsed < effect.fade_out) {
          level *= Math.max(0, (clipDuration - elapsed) / effect.fade_out);
        }
        player.volume = Math.max(0, Math.min(1, level));
        if (player.paused) void player.play().catch(() => undefined);
      });
    };
    syncMusic.current = sync;
    video.addEventListener("play", sync);
    video.addEventListener("pause", sync);
    video.addEventListener("seeking", sync);
    video.addEventListener("timeupdate", sync);
    video.addEventListener("ended", sync);
    return () => {
      video.removeEventListener("play", sync);
      video.removeEventListener("pause", sync);
      video.removeEventListener("seeking", sync);
      video.removeEventListener("timeupdate", sync);
      video.removeEventListener("ended", sync);
      audio.pause();
      narration?.pause();
    };
  }, []);

  useEffect(() => {
    const narration = narrationRef.current;
    const video = videoRef.current;
    if (!narration) return;
    if (video) video.muted = Boolean(narrationUrl) || userMuted.current;
    if (narrationUrl) {
      narration.pause();
      narration.currentTime = 0;
      narration.src = narrationUrl;
      narration.load();
    } else {
      narration.pause();
      narration.removeAttribute("src");
      narration.load();
    }
    syncMusic.current();
  }, [narrationUrl]);

  useEffect(() => {
    const narration = narrationRef.current;
    if (!narration) return;
    narration.addEventListener("canplay", syncMusic.current);
    narration.addEventListener("loadedmetadata", syncMusic.current);
    return () => {
      narration.removeEventListener("canplay", syncMusic.current);
      narration.removeEventListener("loadedmetadata", syncMusic.current);
    };
  }, []);

  useEffect(() => {
    const audio = musicRef.current;
    if (!audio) return;
    if (music?.audio_url) {
      audio.pause();
      audio.currentTime = 0;
      audio.src = music.audio_url;
      audio.load();
    } else {
      audio.pause();
      audio.removeAttribute("src");
      audio.load();
    }
  }, [music?.track_id, music?.audio_url]);

  useEffect(() => {
    const audio = musicRef.current;
    if (!audio) return;
    const sync = () => syncMusic.current();
    audio.addEventListener("canplay", sync);
    audio.addEventListener("loadedmetadata", sync);
    return () => {
      audio.removeEventListener("canplay", sync);
      audio.removeEventListener("loadedmetadata", sync);
    };
  }, []);

  useImperativeHandle(ref, () => ({
    toggle: async () => {
      if (!videoRef.current) return;
      if (videoRef.current.paused) await videoRef.current.play();
      else videoRef.current.pause();
    },
    seek: (time) => { if (videoRef.current) videoRef.current.currentTime = time; },
    volume: (value) => { if (videoRef.current) videoRef.current.volume = value; if (narrationRef.current) narrationRef.current.volume = value; },
    mute: (value) => { userMuted.current = value; if (videoRef.current) videoRef.current.muted = value || Boolean(latest.current.narrationUrl); if (narrationRef.current) narrationRef.current.muted = value; },
  }), []);

  useEffect(() => {
    let frame = 0;
    const draw = () => {
      const canvas = canvasRef.current;
      const video = videoRef.current;
      if (canvas && video && video.readyState >= 2) {
        canvas.width = video.videoWidth || 1080;
        canvas.height = video.videoHeight || 1920;
        const context = canvas.getContext("2d");
        if (context) {
          context.drawImage(video, 0, 0, canvas.width, canvas.height);
          drawCaption(context, canvas, latest.current.caption, latest.current.style, video.currentTime);
        }
      }
      frame = requestAnimationFrame(draw);
    };
    frame = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(frame);
  }, []);

  const move = (event: React.PointerEvent<HTMLElement>) => {
    const drag = dragRef.current;
    if (!drag) return;
    const bounds = stageRef.current?.getBoundingClientRect();
    if (!bounds) return;
    const x = clamp((event.clientX - bounds.left) / bounds.width);
    const y = clamp((event.clientY - bounds.top) / bounds.height);
    if (drag.kind === "caption") onStyleChange({ ...style, x, y });
    else if (drag.kind === "resize") {
      const width = drag.width + (event.clientX - drag.x) / bounds.width;
      onOverlayChange(drag.id, { width: Math.max(.08, Math.min(.95, width)) });
    } else onOverlayChange(drag.id, { x, y });
  };

  return (
    <div className="video-stage" ref={stageRef}>
      <audio crossOrigin="anonymous" preload="auto" ref={musicRef} />
      <audio crossOrigin="anonymous" preload="auto" ref={narrationRef} />
      {soundEffects.map((effect) => <audio key={effect.track_id} onCanPlay={() => syncMusic.current()} preload="auto" ref={(node) => { if (node) effectPlayers.current.set(effect.track_id, node); else effectPlayers.current.delete(effect.track_id); }} src={effect.audio_url} />)}
      <video
        onDurationChange={(event) => onDuration(event.currentTarget.duration)}
        onPause={() => onPlaying(false)}
        onPlay={() => onPlaying(true)}
        onTimeUpdate={(event) => { onTime(event.currentTarget.currentTime); syncMusic.current(); }}
        playsInline
        ref={videoRef}
        src={url}
      />
      <canvas
        aria-label="Video caption canvas"
        onPointerDown={(event) => {
          dragRef.current = { kind: "caption" };
          event.currentTarget.setPointerCapture(event.pointerId);
          move(event);
        }}
        onPointerMove={move}
        onPointerUp={() => { dragRef.current = null; }}
        ref={canvasRef}
      />
      {overlays.filter((item) => currentTime >= item.start && currentTime < item.end).map((item) => <div
        aria-label={item.kind === "text" ? item.text || "Text overlay" : "Image overlay"}
        className={selectedOverlayId === item.id ? "canvas-overlay selected" : "canvas-overlay"}
        key={item.id}
        onClick={() => onOverlaySelect(item.id)}
        onPointerDown={(event) => {
          event.stopPropagation();
          event.currentTarget.setPointerCapture(event.pointerId);
          dragRef.current = { kind: "overlay", id: item.id };
          onOverlaySelect(item.id);
        }}
        onPointerMove={move}
        onPointerUp={() => { dragRef.current = null; }}
        style={{ left: `${item.x * 100}%`, top: `${item.y * 100}%`, width: `${item.width * 100}%`, minHeight: item.kind === "text" ? `${item.height * 100}%` : undefined, opacity: item.opacity * overlayFade(item.style.animation, currentTime - item.start, item.end - currentTime), transform: `translate(-50%, -50%) scale(${overlayScale(item.style.animation, currentTime - item.start)})` }}
      >{item.kind === "image" ? <Image alt="" draggable={false} height={1920} src={item.image_url} unoptimized width={1080} /> : <span style={{ color: item.style.color, backgroundColor: hexColor(item.style.background, item.style.background_opacity), fontFamily: item.style.font, fontSize: `${item.style.size / 10.8}cqw`, fontWeight: item.style.weight, fontStyle: item.style.italic ? "italic" : "normal", textDecoration: item.style.underline ? "underline" : "none", textAlign: item.style.align, letterSpacing: `${item.style.letter_spacing / 10.8}cqw`, textShadow: item.style.shadow ? `0 2px ${item.style.shadow}px #000` : undefined }}>{item.text}</span>}{selectedOverlayId === item.id ? <button aria-label="Resize layer" className="canvas-resize-handle" onPointerDown={(event) => { event.stopPropagation(); event.currentTarget.setPointerCapture(event.pointerId); dragRef.current = { kind: "resize", id: item.id, x: event.clientX, width: item.width }; }} onPointerMove={move} onPointerUp={() => { dragRef.current = null; }} type="button" /> : null}</div>)}
      <span className="canvas-hint">Drag caption to position it</span>
    </div>
  );
});
