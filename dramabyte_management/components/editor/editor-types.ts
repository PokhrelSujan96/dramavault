export type Caption = {
  id: number;
  text: string;
  start: number;
  end: number;
};

export type CaptionStyle = {
  animation: "none" | "fade" | "pop";
  font: string;
  size: number;
  weight: string;
  align: "left" | "center" | "right";
  color: string;
  background: string;
  background_opacity: number;
  x: number;
  y: number;
  max_width: number;
  template: string;
  italic: boolean;
  underline: boolean;
  outline: number;
  outline_color: string;
  shadow: number;
  letter_spacing: number;
};

export type EditorState = {
  captions: Caption[];
  style: CaptionStyle;
  music: BackgroundMusic | null;
  overlays: EditorOverlay[];
  sound_effects: SoundEffect[];
};

export type EditorOverlay = {
  id: string;
  kind: "text" | "image";
  text: string;
  asset_key: string;
  image_url: string;
  x: number;
  y: number;
  width: number;
  height: number;
  opacity: number;
  start: number;
  end: number;
  style: CaptionStyle;
};

export type SoundEffect = {
  track_id: string;
  title: string;
  creator: string;
  source_url: string;
  audio_url: string;
  license: "cc0" | "by";
  license_version: string;
  license_url: string;
  attribution: string;
  duration: number;
  start: number;
  trim_start: number;
  trim_end: number;
  volume: number;
  fade_in: number;
  fade_out: number;
};

export type BackgroundMusic = {
  track_id: string;
  title: string;
  creator: string;
  source_url: string;
  audio_url: string;
  license: "cc0" | "by";
  license_version: string;
  license_url: string;
  attribution: string;
  duration: number;
  volume: number;
  fade_in: number;
  fade_out: number;
  start: number;
};
