import { Plus } from "lucide-react";
import type { Caption } from "@/components/editor/editor-types";

type Props = {
  captions: Caption[];
  activeId: number;
  onChange: (id: number, text: string) => void;
  onTiming: (id: number, start: number, end: number) => void;
  onAdd: () => void;
  onSelect: (caption: Caption) => void;
};

export function CaptionPanel({ captions, activeId, onChange, onTiming, onAdd, onSelect }: Props) {
  return (
    <aside className="caption-panel">
      <div className="editor-panel-title"><h2>Captions</h2><button aria-label="Add caption" onClick={onAdd} type="button"><Plus size={17} /></button></div>
      <div className="caption-tabs"><button className="active" type="button">Captions</button><button type="button">Settings</button></div>
      <div className="caption-list">
        {captions.map((caption) => (
          <article className={caption.id === activeId ? "caption-row active" : "caption-row"} key={caption.id} onClick={() => onSelect(caption)}>
            <div className="caption-times"><input aria-label="Caption start time" min="0" onChange={(event) => onTiming(caption.id, Number(event.target.value), caption.end)} step="0.1" type="number" value={caption.start} /><input aria-label="Caption end time" min="0.1" onChange={(event) => onTiming(caption.id, caption.start, Number(event.target.value))} step="0.1" type="number" value={caption.end} /></div>
            <textarea aria-label={`Caption ${caption.id + 1}`} onChange={(event) => onChange(caption.id, event.target.value)} rows={2} value={caption.text} />
          </article>
        ))}
      </div>
    </aside>
  );
}
