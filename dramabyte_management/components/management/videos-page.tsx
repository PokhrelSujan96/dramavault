import { useState } from "react";
import { useManagement } from "@/hooks/use-management";
import type { StoryProject } from "@/lib/project-types";
import { ProjectThumbnail } from "@/components/dashboard/project-thumbnail";

type Props = { query: string; onOpen: (project: StoryProject) => void };
export function VideosPage({ query, onOpen }: Props) {
  const [page, setPage] = useState(1);
  const [filter, setFilter] = useState("all");
  const data = useManagement<StoryProject>(`/admin/videos?page=${page}&size=25`);
  const projects = data.items.filter((item) => item.title.toLowerCase().includes(query.toLowerCase()) && (filter === "all" || item.status === filter));
  return <section className="management-page"><header><div><h1>Video library</h1><p>Review productions and manage videos available in the app.</p></div><select aria-label="Filter videos" value={filter} onChange={(event) => setFilter(event.target.value)}>{["all", "published", "ready", "draft", "failed", "generating"].map((status) => <option key={status}>{status}</option>)}</select></header>
    {data.error && <p className="dashboard-error" role="alert">{data.error}</p>}
    <div className="management-video-grid">{projects.map((project) => <article className="management-card" key={project.id}><div className="management-video-art"><ProjectThumbnail project={project} /><span>{project.title}</span></div><div className="management-video-copy"><h3>{project.title}</h3><p>{project.language.toUpperCase()} · {project.status}</p><div className="management-actions"><button onClick={() => onOpen(project)}>Open editor</button><button disabled={data.busy || !["ready", "published"].includes(project.status)} onClick={() => void data.mutate(`/admin/videos/${project.id}`, "PATCH", { status: project.status === "published" ? "ready" : "published" })}>{project.status === "published" ? "Unpublish" : "Publish"}</button><button disabled={data.busy || ["queued", "generating"].includes(project.status)} onClick={() => { if (window.confirm(`Delete “${project.title}” and its project records? This cannot be undone.`)) void data.mutate(`/admin/videos/${project.id}`, "DELETE"); }}>Delete</button></div></div></article>)}</div>
    {!projects.length && <p className="empty-state">{data.busy ? "Loading videos…" : "No matching videos on this page."}</p>}
    <footer><button disabled={page === 1 || data.busy} onClick={() => setPage(page - 1)}>Previous</button><span>Page {page}</span><button disabled={page * 25 >= data.total || data.busy} onClick={() => setPage(page + 1)}>Next</button></footer>
  </section>;
}
