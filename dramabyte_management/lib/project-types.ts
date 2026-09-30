export type ProjectStatus =
  | "draft"
  | "queued"
  | "generating"
  | "review"
  | "ready"
  | "published"
  | "failed";

export type StoryProject = {
  id: string;
  owner_id: string;
  title: string;
  premise: string;
  script: string;
  language: string;
  aspect_ratio: string;
  production_mode?: "narrated" | "dialogue_pilot";
  status: ProjectStatus;
  current_stage: string;
  progress: number;
  created_at: string;
  updated_at: string;
};

export type ProjectDraft = {
  title: string;
  premise: string;
  script: string;
  language: string;
  aspect_ratio: string;
};

export type GenerationResult = {
  status: ProjectStatus;
  stage: string;
  progress: number;
  final_url?: string;
  preview_url?: string;
  published_url?: string;
  localization?: import("@/components/editor/language-panel").HindiTrack | null;
  audio_tracks?: Record<string, { url: string; voice_url?: string | null }>;
  editor?: import("@/components/editor/editor-types").EditorState;
  error?: string;
};
