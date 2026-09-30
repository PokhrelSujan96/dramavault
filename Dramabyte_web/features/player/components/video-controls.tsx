"use client";

import { useEffect, useState, type RefObject } from "react";
import { Maximize, Minimize, Pause, Play, Volume2, VolumeX } from "lucide-react";
import styles from "./video-controls.module.css";

type Props = {
  video: RefObject<HTMLVideoElement | null>;
  frame: RefObject<HTMLDivElement | null>;
  playing: boolean;
  toggle: () => Promise<void>;
};

function timestamp(value: number) {
  const seconds = Math.floor(Number.isFinite(value) ? Math.max(0, value) : 0);
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;
}

export function VideoControls({ video, frame, playing, toggle }: Props) {
  const [position, setPosition] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(1);
  const [speed, setSpeed] = useState(1);
  const [fullscreen, setFullscreen] = useState(false);
  const [waiting, setWaiting] = useState(false);
  useEffect(() => {
    const element = video.current;
    if (!element) return;
    const sync = () => {
      setPosition(element.currentTime || 0);
      setDuration(Number.isFinite(element.duration) ? element.duration : 0);
      setVolume(element.muted ? 0 : element.volume);
      setSpeed(element.playbackRate);
    };
    const busy = () => setWaiting(true);
    const ready = () => setWaiting(false);
    const screen = () => setFullscreen(document.fullscreenElement === frame.current);
    const events = ["timeupdate", "durationchange", "loadedmetadata", "volumechange", "ratechange", "emptied"];
    events.forEach((event) => element.addEventListener(event, sync));
    element.addEventListener("waiting", busy);
    element.addEventListener("playing", ready);
    element.addEventListener("canplay", ready);
    element.addEventListener("pause", ready);
    document.addEventListener("fullscreenchange", screen);
    sync();
    return () => {
      events.forEach((event) => element.removeEventListener(event, sync));
      element.removeEventListener("waiting", busy);
      element.removeEventListener("playing", ready);
      element.removeEventListener("canplay", ready);
      element.removeEventListener("pause", ready);
      document.removeEventListener("fullscreenchange", screen);
    };
  }, [video, frame]);
  const seek = (value: number) => {
    if (video.current && duration > 0) video.current.currentTime = Math.max(0, Math.min(duration, value));
  };
  const changeVolume = (value: number) => {
    if (!video.current) return;
    video.current.volume = value;
    video.current.muted = value === 0;
  };
  const mute = () => {
    const element = video.current;
    if (element) { if (element.volume === 0) element.volume = 1; element.muted = !element.muted; }
  };
  const expand = async () => {
    try {
      if (document.fullscreenElement) await document.exitFullscreen();
      else await frame.current?.requestFullscreen();
    } catch { setFullscreen(false); }
  };
  return <div className={styles.controls} onKeyDown={(event) => {
    if (event.target instanceof HTMLInputElement || event.target instanceof HTMLSelectElement) return;
    if (event.key === "ArrowRight" || event.key === "ArrowLeft") { event.preventDefault(); seek(position + (event.key === "ArrowRight" ? 5 : -5)); }
  }}>
    {waiting && <span className={styles.loading} role="status">Buffering…</span>}
    <input className={styles.seek} type="range" aria-label="Seek video" aria-valuetext={`${timestamp(position)} of ${timestamp(duration)}`} min={0} max={duration || 1} step={0.1} value={Math.min(position, duration)} disabled={!duration} onChange={(event) => seek(Number(event.target.value))} />
    <div className={styles.row}>
      <button onClick={toggle} aria-label={playing ? "Pause video" : "Play video"}>{playing ? <Pause size={19} /> : <Play size={19} />}</button>
      <span className={styles.time}>{timestamp(position)} / {timestamp(duration)}</span>
      <button onClick={mute} aria-label={volume ? "Mute video" : "Unmute video"}>{volume ? <Volume2 size={19} /> : <VolumeX size={19} />}</button>
      <input className={styles.volume} type="range" aria-label="Volume" min={0} max={1} step={0.05} value={volume} onChange={(event) => changeVolume(Number(event.target.value))} />
      <select aria-label="Playback speed" value={speed} onChange={(event) => { if (video.current) video.current.playbackRate = Number(event.target.value); }}>{[0.5, 1, 1.25, 1.5, 2].map((rate) => <option key={rate} value={rate}>{rate}×</option>)}</select>
      <button onClick={expand} aria-label={fullscreen ? "Exit fullscreen" : "Enter fullscreen"}>{fullscreen ? <Minimize size={19} /> : <Maximize size={19} />}</button>
    </div>
  </div>;
}
