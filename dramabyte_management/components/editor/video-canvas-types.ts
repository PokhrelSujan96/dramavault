import type {
  BackgroundMusic,
  Caption,
  CaptionStyle,
  EditorOverlay,
  SoundEffect,
} from "@/components/editor/editor-types";

export type VideoCanvasProps = {
  url: string;
  narrationUrl?: string | null;
  caption?: Caption;
  style: CaptionStyle;
  music: BackgroundMusic | null;
  currentTime: number;
  overlays: EditorOverlay[];
  soundEffects: SoundEffect[];
  selectedOverlayId: string | null;
  onOverlayChange: (id: string, patch: Partial<EditorOverlay>) => void;
  onOverlaySelect: (id: string) => void;
  onStyleChange: (style: CaptionStyle) => void;
  onDuration: (duration: number) => void;
  onTime: (time: number) => void;
  onPlaying: (playing: boolean) => void;
};

export type VideoCanvasHandle = {
  toggle: () => Promise<void>;
  seek: (time: number) => void;
  volume: (value: number) => void;
  mute: (value: boolean) => void;
};
