import { AlignCenter, AlignLeft, AlignRight } from "lucide-react";
import type { CaptionStyle } from "@/components/editor/editor-types";

type Props = {
  style: CaptionStyle;
  onChange: (value: CaptionStyle) => void;
};

const templates: Record<string, Partial<CaptionStyle>> = {
  classic: { font: "Poppins", weight: "700", color: "#ffffff", background: "#111111", background_opacity: .82, outline: 0 },
  minimal: { font: "Inter", weight: "600", color: "#ffffff", background: "#111111", background_opacity: 0, outline: 1.5 },
  cinema: { font: "Georgia", weight: "700", color: "#fff6d8", background: "#000000", background_opacity: .72, outline: 0 },
  impact: { font: "Impact", weight: "900", color: "#fff200", background: "#000000", background_opacity: 0, outline: 2 },
};

export function StylePanel({ style, onChange }: Props) {
  const set = <K extends keyof CaptionStyle>(key: K, value: CaptionStyle[K]) => onChange({ ...style, [key]: value });
  const template = (name: string) => onChange({ ...style, ...templates[name], template: name });
  return (
    <aside className="style-panel">
      <div className="style-title"><h2>Styles</h2><span>Live canvas</span></div>
      <section><p>Templates</p><div className="template-grid">{Object.keys(templates).map((name) => <button className={style.template === name ? "active" : ""} key={name} onClick={() => template(name)} type="button">{name}</button>)}</div></section>
      <section><p>Fonts</p><label>Family<select onChange={(event) => set("font", event.target.value)} value={style.font}><option>Inter</option><option>Poppins</option><option>Roboto</option><option>Arial</option><option>Montserrat</option><option>Georgia</option><option>Impact</option></select></label><label>Weight<select onChange={(event) => set("weight", event.target.value)} value={style.weight}><option value="400">Regular</option><option value="500">Medium</option><option value="600">Semibold</option><option value="700">Bold</option><option value="800">Extra bold</option><option value="900">Black</option></select></label><label>Size<input max="120" min="18" onChange={(event) => set("size", Number(event.target.value))} type="range" value={style.size} /><strong>{style.size}</strong></label></section>
      <section><p>Format</p><label>Styles<span className="align-buttons"><button aria-pressed={style.italic} className={style.italic ? "active" : ""} onClick={() => set("italic", !style.italic)} type="button">I</button><button aria-pressed={style.underline} className={style.underline ? "active" : ""} onClick={() => set("underline", !style.underline)} type="button"><u>U</u></button></span></label><label>Alignment<span className="align-buttons"><button className={style.align === "left" ? "active" : ""} onClick={() => set("align", "left")} type="button"><AlignLeft size={16} /></button><button className={style.align === "center" ? "active" : ""} onClick={() => set("align", "center")} type="button"><AlignCenter size={16} /></button><button className={style.align === "right" ? "active" : ""} onClick={() => set("align", "right")} type="button"><AlignRight size={16} /></button></span></label><label>Position<select onChange={(event) => set("y", Number(event.target.value))} value={closestPosition(style.y)}><option value="0.16">Top</option><option value="0.5">Middle</option><option value="0.82">Bottom</option></select></label><label>Side padding<input max="0.95" min="0.25" onChange={(event) => set("max_width", Number(event.target.value))} step="0.01" type="range" value={style.max_width} /></label><label>Fine X<input max="0.95" min="0.05" onChange={(event) => set("x", Number(event.target.value))} step="0.005" type="range" value={style.x} /></label><label>Fine Y<input max="0.95" min="0.05" onChange={(event) => set("y", Number(event.target.value))} step="0.005" type="range" value={style.y} /></label></section>
      <section><p>Color</p><label>Text<input onChange={(event) => set("color", event.target.value)} type="color" value={style.color} /></label><label>Background<input onChange={(event) => set("background", event.target.value)} type="color" value={style.background} /></label><label>Opacity<input max="1" min="0" onChange={(event) => set("background_opacity", Number(event.target.value))} step="0.05" type="range" value={style.background_opacity} /></label></section>
      <section><p>Animation</p><label>Entrance<select onChange={(event) => set("animation", event.target.value as CaptionStyle["animation"])} value={style.animation}><option value="none">None</option><option value="fade">Fade</option><option value="pop">Pop</option></select></label></section>
      <section><p>Effects</p><label>Outline<input max="8" min="0" onChange={(event) => set("outline", Number(event.target.value))} step="0.25" type="range" value={style.outline} /></label><label>Outline color<input onChange={(event) => set("outline_color", event.target.value)} type="color" value={style.outline_color} /></label><label>Shadow<input max="8" min="0" onChange={(event) => set("shadow", Number(event.target.value))} step="0.25" type="range" value={style.shadow} /></label><label>Letter spacing<input max="20" min="-5" onChange={(event) => set("letter_spacing", Number(event.target.value))} step="0.5" type="range" value={style.letter_spacing} /></label></section>
      <section className="position-readout"><p>Canvas position</p><span>X {Math.round(style.x * 100)}%</span><span>Y {Math.round(style.y * 100)}%</span></section>
    </aside>
  );
}

function closestPosition(y: number) {
  if (y < .33) return .16;
  if (y < .67) return .5;
  return .82;
}
