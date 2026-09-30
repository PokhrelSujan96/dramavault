import { useState } from "react";
import { apiRequest } from "@/lib/api-client";
import { loadQuery } from "@/lib/query-cache";
import { EpisodeFields, defaultEpisodeMetadata } from "./episode-fields";

export function UploadEpisode({ seriesId, onUploaded }: { seriesId: string; onUploaded: () => Promise<void> }) {
  const [metadata, setMetadata] = useState(defaultEpisodeMetadata);
  const [file, setFile] = useState<File>();
  const [number, setNumber] = useState(1);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  async function upload() {
    if (!file || !metadata.title.trim()) { setError("Choose an MP4 file and enter an episode title."); return; }
    if (file.size > 250 * 1024 * 1024) { setError("Video must be under 250 MB."); return; }
    setBusy(true); setError(""); setSuccess(false);
    const body = new FormData(); body.set("file", file); body.set("episode_number", String(number));
    body.set("title", metadata.title); body.set("description", metadata.description); body.set("thumbnail_url", metadata.thumbnail_url);
    try {
      await apiRequest(`/admin/series/${seriesId}/upload`, { method: "POST", body });
      await onUploaded();
      for (const key of ["/admin/series", "/admin/overview", "/projects"]) void loadQuery(key, () => apiRequest(key), true);
      setSuccess(true);
    } catch (cause) { setError(cause instanceof Error ? cause.message : "Upload failed"); }
    finally { setBusy(false); }
  }
  return <form onSubmit={(event) => { event.preventDefault(); void upload(); }}><h3>Upload an episode</h3><p>MP4 · up to 250 MB. The actual duration is detected automatically. Uploads are saved for review; publish them from Productions.</p><label>Video file<input required type="file" accept="video/mp4,.mp4" onChange={(event) => { setFile(event.target.files?.[0]); setSuccess(false); }} /></label><label>Episode number<input required type="number" min={1} max={100000} value={number} onChange={(event) => setNumber(Number(event.target.value))} /></label><EpisodeFields value={metadata} onChange={setMetadata} showDuration={false} />{error && <p role="alert" className="dashboard-error">{error}</p>}{success && <p role="status">Episode uploaded and ready to review.</p>}<button disabled={busy || success}>{busy ? "Uploading episode…" : success ? "Uploaded" : "Upload episode"}</button></form>;
}
