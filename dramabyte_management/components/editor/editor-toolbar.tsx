import { Captions, Image, Music2, Settings2, Type } from "lucide-react";

const tools = [
  [Captions, "Captions"],
  [Type, "Text"],
  [Image, "Media"],
  [Music2, "Audio"],
  [Settings2, "Options"],
] as const;

export function EditorToolbar({ active = "Captions", onSelect }: { active?: string; onSelect?: (tool: string) => void }) {
  return (
    <nav className="editor-toolbar" aria-label="Editor tools">
      {tools.map(([Icon, label]) => (
        <button className={active === label ? "active" : ""} key={label} onClick={() => onSelect?.(label)} type="button">
          <Icon size={18} /><span>{label}</span>
        </button>
      ))}
    </nav>
  );
}
