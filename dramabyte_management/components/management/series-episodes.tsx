import { useState } from "react";
import { useManagement } from "@/hooks/use-management";
import type { StoryProject } from "@/lib/project-types";
import type { Series } from "./management-types";
import { SeriesFields, defaultSeriesMetadata } from "./series-fields";
import { EpisodeFields, defaultEpisodeMetadata, type EpisodeMetadata } from "./episode-fields";
import { EpisodeDetails } from "./episode-details";
import { UploadEpisode } from "./upload-episode";
import { CharacterLibrary } from "./character-library";

type Episode = EpisodeMetadata & { id: string; episode_number: number; projects: StoryProject; views?: number; likes?: number; comments?: number };
export function SeriesEpisodes({ series, onClose }: { series: Series; onClose: () => void; onChanged: () => Promise<void> }) {
  const episodes = useManagement<Episode>(`/admin/series/${series.id}/episodes`);
  const [videoPage, setVideoPage] = useState(1);
  const videos = useManagement<StoryProject>(`/admin/videos?page=${videoPage}&size=100`);
  const [title, setTitle] = useState(series.title);
  const [description, setDescription] = useState(series.description);
  const [projectId, setProjectId] = useState("");
  const [number, setNumber] = useState(1);
  const [renumberId, setRenumberId] = useState("");
  const [newNumber, setNewNumber] = useState(1);
  const [metadata, setMetadata] = useState({ ...defaultSeriesMetadata, thumbnail_url: series.thumbnail_url ?? "", genre: series.genre ?? "Drama", target_episode_count: series.target_episode_count ?? 15, target_episode_seconds: series.target_episode_seconds ?? 60 });
  const [episodeMetadata, setEpisodeMetadata] = useState(defaultEpisodeMetadata);
  const [editing, setEditing] = useState<Episode>();
  return <div className="management-modal" role="dialog" aria-modal="true" aria-label="Series episodes"><section className="profile-panel"><header><h2>{series.title}</h2><button onClick={onClose}>Close</button></header>
    {(episodes.error || videos.error) && <p className="dashboard-error" role="alert">{episodes.error || videos.error}</p>}
    <form onSubmit={(event) => { event.preventDefault(); void episodes.mutate(`/admin/series/${series.id}`, "PATCH", { title, description, ...metadata }); }}><h3>Series details</h3><label>Title<input required maxLength={160} value={title} onChange={(event) => setTitle(event.target.value)} /></label><label>Description<textarea maxLength={5000} value={description} onChange={(event) => setDescription(event.target.value)} /></label><SeriesFields value={metadata} onChange={setMetadata} /><button disabled={episodes.busy}>Save details</button></form>
    <form onSubmit={(event) => { event.preventDefault(); void episodes.mutate(`/admin/series/${series.id}/episodes`, "POST", { project_id: projectId, episode_number: number, ...episodeMetadata }).then((success) => { if (success) { setProjectId(""); setNumber(number + 1); } }); }}><h3>Add episode</h3><EpisodeFields value={episodeMetadata} onChange={setEpisodeMetadata} /><label>Video<select required value={projectId} onChange={(event) => setProjectId(event.target.value)}><option value="">Choose a production</option>{videos.items.map((project) => <option value={project.id} key={project.id}>{project.title} · {project.status}</option>)}</select></label><div className="management-actions"><button type="button" disabled={videoPage === 1 || videos.busy} onClick={() => setVideoPage(videoPage - 1)}>Previous videos</button><button type="button" disabled={videoPage * 100 >= videos.total || videos.busy} onClick={() => setVideoPage(videoPage + 1)}>More videos</button></div><label>Episode number<input type="number" required min={1} max={100000} value={number} onChange={(event) => setNumber(Number(event.target.value))} /></label><button disabled={episodes.busy || !projectId}>Add episode</button></form>
    <CharacterLibrary seriesId={series.id} />
    <UploadEpisode seriesId={series.id} onUploaded={async () => { await episodes.reload(); await videos.reload(); }} />
    {editing && <EpisodeDetails key={editing.id} episode={editing} seriesId={series.id} onClose={() => setEditing(undefined)} />}
    <h3>Episodes</h3><table><thead><tr><th>Episode</th><th>Title</th><th>Status</th><th>Views</th><th>Likes</th><th>Comments</th><th /></tr></thead><tbody>{episodes.items.map((episode) => <tr key={episode.id}><td>{episode.episode_number}</td><td>{episode.title || episode.projects.title}</td><td>{episode.projects.status}</td><td>{episode.views ?? 0}</td><td>{episode.likes ?? 0}</td><td>{episode.comments ?? 0}</td><td><button type="button" onClick={() => setEditing(episode)}>Edit</button><button disabled={episodes.busy} onClick={() => { if (window.confirm("Remove this episode from the series? The video will remain.")) void episodes.mutate(`/admin/episodes/${episode.id}`, "DELETE"); }}>Remove</button></td></tr>)}</tbody></table>{!episodes.items.length && <p>No episodes yet.</p>}
    <form onSubmit={(event) => { event.preventDefault(); void episodes.mutate(`/admin/episodes/${renumberId}`, "PATCH", { episode_number: newNumber }); }}><h3>Renumber episode</h3><label>Episode<select required value={renumberId} onChange={(event) => setRenumberId(event.target.value)}><option value="">Choose an episode</option>{episodes.items.map((item) => <option key={item.id} value={item.id}>{item.episode_number} · {item.projects.title}</option>)}</select></label><label>New number<input type="number" min={1} max={100000} required value={newNumber} onChange={(event) => setNewNumber(Number(event.target.value))} /></label><button disabled={episodes.busy || !renumberId}>Save episode number</button></form>
    <button disabled={episodes.busy} onClick={() => { if (window.confirm("Delete this series and episode assignments? Videos will remain.")) void episodes.mutate(`/admin/series/${series.id}`, "DELETE").then((success) => { if (success) onClose(); }); }}>Delete series</button>
  </section></div>;
}
