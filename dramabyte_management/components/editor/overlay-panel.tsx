"use client";

import { ImagePlus, Plus, Trash2, Type } from "lucide-react";
import { useRef, useState } from "react";
import Image from "next/image";
import type { EditorOverlay } from "@/components/editor/editor-types";

type Props = {
  mode: "Text" | "Media";
  overlays: EditorOverlay[];
  selectedId: string | null;
  onAddText: () => void;
  onSelect: (id: string) => void;
  onUpdate: (id: string, patch: Partial<EditorOverlay>) => void;
  onRemove: (id: string) => void;
  onUpload: (file: File) => Promise<void>;
};

export function OverlayPanel({
  mode,
  overlays,
  selectedId,
  onAddText,
  onSelect,
  onUpdate,
  onRemove,
  onUpload,
}: Props) {
  const input = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState("");
  const visible = overlays.filter((item) => item.kind === (mode === "Text" ? "text" : "image"));
  const selected = overlays.find((item) => item.id === selectedId);

  const upload = async (file?: File) => {
    if (!file) return;
    setUploading(true);
    setError("");
    try {
      await onUpload(file);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Image upload failed");
    } finally {
      setUploading(false);
      if (input.current) input.current.value = "";
    }
  };

  return (
    <aside className="overlay-panel">
      <div className="editor-panel-title">
        <h2>{mode === "Text" ? "Text layers" : "Media library"}</h2>
        {mode === "Text" ? (
          <button aria-label="Add text layer" onClick={onAddText} type="button"><Plus size={17} /></button>
        ) : (
          <button aria-label="Upload image" disabled={uploading} onClick={() => input.current?.click()} type="button"><ImagePlus size={17} /></button>
        )}
      </div>
      {mode === "Text" ? <button className="overlay-add-button" onClick={onAddText} type="button"><Type size={16} /> Add text</button> : null}
      {mode === "Media" ? <div className="overlay-upload">
        <input accept="image/png,image/jpeg,image/webp" hidden onChange={(event) => void upload(event.target.files?.[0])} ref={input} type="file" />
        <button disabled={uploading} onClick={() => input.current?.click()} type="button"><ImagePlus size={17} /> {uploading ? "Uploading…" : "Upload image"}</button>
        <small>PNG, JPEG, or WebP · up to 20 MB</small>
      </div> : null}
      {error ? <p className="editor-error" role="alert">{error}</p> : null}
      <div className="overlay-list">
        {visible.map((item) => <button className={selectedId === item.id ? "selected" : ""} key={item.id} onClick={() => onSelect(item.id)} type="button">
          {item.kind === "image" && item.image_url ? <Image alt="" height={48} src={item.image_url} unoptimized width={56} /> : <Type size={17} />}
          <span>{item.kind === "text" ? item.text || "Text layer" : "Image layer"}</span>
          <small>{formatTime(item.start)}–{formatTime(item.end)}</small>
        </button>)}
        {!visible.length ? <p>{mode === "Text" ? "Add a title, label, or on-screen note." : "Upload an image to add it over the video."}</p> : null}
      </div>
      {selected ? <section className="overlay-properties">
        <div className="editor-panel-title"><h2>Layer timing</h2><button aria-label="Delete layer" onClick={() => onRemove(selected.id)} type="button"><Trash2 size={15} /></button></div>
        {selected.kind === "text" ? <label>Text<textarea maxLength={500} onChange={(event) => onUpdate(selected.id, { text: event.target.value })} rows={3} value={selected.text} /></label> : null}
        <label>Start <input max={3600} min={0} onChange={(event) => onUpdate(selected.id, { start: Number(event.target.value) })} step="0.1" type="number" value={selected.start} /></label>
        <label>End <input max={3600} min={0.1} onChange={(event) => onUpdate(selected.id, { end: Number(event.target.value) })} step="0.1" type="number" value={selected.end} /></label>
        <label>Size <input max="0.95" min="0.08" onChange={(event) => onUpdate(selected.id, { width: Number(event.target.value) })} step="0.01" type="range" value={selected.width} /><output>{Math.round(selected.width * 100)}%</output></label>
        {selected.kind === "image" ? <label>Opacity <input max="1" min="0" onChange={(event) => onUpdate(selected.id, { opacity: Number(event.target.value) })} step="0.05" type="range" value={selected.opacity} /></label> : null}
      </section> : null}
    </aside>
  );
}

const formatTime = (value: number) => `0:${String(Math.floor(value)).padStart(2, "0")}`;
