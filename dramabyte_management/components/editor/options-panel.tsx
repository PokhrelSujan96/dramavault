type Props = { aspect: string; duration: number };

export function OptionsPanel({ aspect, duration }: Props) {
  const dimensions = aspect === "16:9" ? "1920 × 1080" : aspect === "1:1" ? "1080 × 1080" : "1080 × 1920";
  return <aside className="options-panel">
    <div className="editor-panel-title"><h2>Project settings</h2></div>
    <section><h3>Canvas</h3><p>Aspect ratio</p><strong>{aspect}</strong><p>Export frame</p><strong>{dimensions} · Full HD</strong><p>Duration</p><strong>{formatTime(duration)}</strong></section>
    <section><h3>Export behavior</h3><p>Edits are rendered as a new public export. Your original production master remains unchanged and is used when you reopen this editor.</p><p>Images, text layers, captions, narration, music, and sound effects are composited into the exported video.</p></section>
  </aside>;
}

const formatTime = (seconds: number) => `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, "0")}`;
