export type PilotCharacter = { id: string; name: string; description?: string; voice_reference?: string };

export type PilotShot = {
  index: number;
  role: "establishing" | "dialogue" | "detail" | "reaction";
  text: string;
  action: string;
  camera: string;
  seconds: number;
  speaker_id: string | null;
  voice_key: string | null;
};

export type DialoguePilot = {
  id: string;
  project_id: string;
  state: "draft" | "queued" | "voices" | "review" | "video" | "motion_review" | "ready" | "failed";
  plan: { title: string; location: string; continuity: string; shots: PilotShot[] };
  cast_snapshot: PilotCharacter[];
  budget_cents: number;
  reserved_cents: number;
  asset_urls: Record<string, string>;
  approvals: Record<string, boolean>;
  estimate: Record<string, number>;
  error_message: string | null;
  paid_generation_enabled: boolean;
};

export const PILOT_VOICES = {
  narrator: "dcd006182803481390993aa6e9669207",
  girl: "83c19893c4974594839bd2d101b1fd66",
  boy: "802e3bc2b27e49c2995d23ef70e6ac89",
};
