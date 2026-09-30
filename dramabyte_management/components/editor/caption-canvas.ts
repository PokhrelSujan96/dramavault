import type { Caption, CaptionStyle } from "@/components/editor/editor-types";

export function drawCaption(
  context: CanvasRenderingContext2D,
  canvas: HTMLCanvasElement,
  caption: Caption | undefined,
  style: CaptionStyle,
  currentTime: number,
) {
  if (!caption?.text) return;
  const scale = canvas.width / 1080;
  const size = style.size * scale;
  const maxWidth = canvas.width * style.max_width;
  context.font = `${style.italic ? "italic " : ""}${style.weight} ${size}px ${style.font}`;
  context.textAlign = style.align;
  context.textBaseline = "middle";
  const lines = wrap(context, caption.text, maxWidth);
  const lineHeight = size * 1.2;
  const x = canvas.width * style.x;
  const y = canvas.height * style.y;
  const elapsed = currentTime - caption.start;
  const remaining = caption.end - currentTime;
  const fade = style.animation === "fade"
    ? Math.min(1, elapsed / .14, remaining / .14)
    : 1;
  const scaleFactor = style.animation === "pop"
    ? 0.82 + 0.18 * Math.min(1, Math.max(0, elapsed / .16))
    : 1;
  context.save();
  context.globalAlpha *= Math.max(0, fade);
  context.translate(x, y);
  context.scale(scaleFactor, scaleFactor);
  context.translate(-x, -y);
  const widest = Math.max(...lines.map((line) => context.measureText(line).width));
  const left = style.align === "center" ? x - widest / 2 : style.align === "right" ? x - widest : x;
  context.fillStyle = hexColor(style.background, style.background_opacity);
  context.fillRect(left - size * .28, y - lines.length * lineHeight / 2 - size * .18, widest + size * .56, lines.length * lineHeight + size * .36);
  if (style.outline > 0) {
    context.strokeStyle = style.outline_color;
    context.lineWidth = style.outline * scale;
    context.lineJoin = "round";
    lines.forEach((line, index) => context.strokeText(line, x, y + (index - (lines.length - 1) / 2) * lineHeight));
  }
  context.shadowBlur = style.shadow * scale;
  context.shadowColor = "#000000";
  context.fillStyle = style.color;
  lines.forEach((line, index) => context.fillText(line, x, y + (index - (lines.length - 1) / 2) * lineHeight));
  context.shadowBlur = 0;
  if (style.underline) drawUnderline(context, lines, x, y, lineHeight, size, scale, style);
  context.restore();
}

function drawUnderline(
  context: CanvasRenderingContext2D,
  lines: string[],
  x: number,
  y: number,
  lineHeight: number,
  size: number,
  scale: number,
  style: CaptionStyle,
) {
  context.strokeStyle = style.color;
  context.lineWidth = Math.max(1, scale * 2);
  lines.forEach((line, index) => {
    const width = context.measureText(line).width;
    const left = style.align === "center" ? x - width / 2 : style.align === "right" ? x - width : x;
    const baseline = y + (index - (lines.length - 1) / 2) * lineHeight + size * .42;
    context.beginPath();
    context.moveTo(left, baseline);
    context.lineTo(left + width, baseline);
    context.stroke();
  });
}

function wrap(context: CanvasRenderingContext2D, text: string, width: number) {
  const lines: string[] = [];
  let line = "";
  text.split(/\s+/).forEach((word) => {
    const next = line ? `${line} ${word}` : word;
    if (line && context.measureText(next).width > width) {
      lines.push(line);
      line = word;
    } else line = next;
  });
  if (line) lines.push(line);
  return lines;
}

export const clamp = (value: number) => Math.max(.05, Math.min(.95, value));

export function overlayFade(animation: string, elapsed: number, remaining: number) {
  if (animation !== "fade") return 1;
  return Math.max(0, Math.min(1, elapsed / .14, remaining / .14));
}

export function overlayScale(animation: string, elapsed: number) {
  return animation === "pop" ? .82 + .18 * Math.min(1, Math.max(0, elapsed / .16)) : 1;
}

export function hexColor(value: string, opacity: number) {
  const red = parseInt(value.slice(1, 3), 16);
  const green = parseInt(value.slice(3, 5), 16);
  const blue = parseInt(value.slice(5, 7), 16);
  return `rgba(${red}, ${green}, ${blue}, ${opacity})`;
}
