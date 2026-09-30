export type HybridShot = {
  id: string;
  shot_index: number;
  kind: "motion" | "still";
  narration: string;
  prompt: string;
  duration_seconds: number;
  image_url?: string;
  approved: boolean;
  motion_approved: boolean;
  video_url?: string;
  start_seconds?: number;
  end_seconds?: number;
  scene_spec?: {
    location: string;
    setting: string;
    subject: string;
    action: string;
    camera: string;
    camera_movement?: string;
    crowd?: string;
    required_details: string[];
    forbidden_details: string[];
    continuity: string;
  };
};

export type HybridState = {
  project_status: string;
  error?: string | null;
  series_id?: string;
  episode_number?: number;
  characters: { id: string; name: string }[];
  run?: { id: string; state: string; duration_seconds?: number };
  shots: HybridShot[];
};
