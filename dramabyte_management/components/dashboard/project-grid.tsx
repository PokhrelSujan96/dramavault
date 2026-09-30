import { ArrowUpRight, Grid2X2, List, Play } from "lucide-react";
import { useState } from "react";
import { ProjectThumbnail } from "./project-thumbnail";
import type { StoryProject } from "@/lib/project-types";

type Props = {
  filter: string;
  projects: StoryProject[];
  query: string;
  onFilterChange: (filter: string) => void;
  onOpenProject: (project: StoryProject) => void;
  onPreview: (project: StoryProject) => void;
};

export function ProjectGrid({ filter, projects, query, onFilterChange, onOpenProject, onPreview }: Props) {
  const [layout, setLayout] = useState("grid");
  const filtered = projects.filter((project) => {
    const matchesFilter = filter === "All" || project.status === filter.toLowerCase();
    return matchesFilter && project.title.toLowerCase().includes(query.toLowerCase());
  });

  return (
    <section className="projects-section" id="recent-projects">
      <div className="section-heading">
        <div><h2>Recent Drama Projects</h2></div>
        <div className="filters" role="group" aria-label="Project status">
          {["All", "Draft", "Generating", "Ready", "Published"].map((item) => (
            <button
              className={filter === item ? "selected" : ""}
              key={item}
              onClick={() => onFilterChange(item)}
              type="button"
            >
              {item === "All" ? "All projects" : item}
            </button>
          ))}
        </div>
      </div>
      <div className="project-view-controls"><button type="button" aria-label="List view" aria-pressed={layout === "list"} onClick={() => setLayout("list")}><List size={17} /></button><button type="button" aria-label="Grid view" aria-pressed={layout === "grid"} onClick={() => setLayout("grid")}><Grid2X2 size={17} /></button></div>
      <div className={`project-grid ${layout === "list" ? "project-list" : ""}`}>
        {filtered.map((project, index) => {
          const tones = ["indigo", "crimson", "slate", "amber"];
          const label = project.status[0].toUpperCase() + project.status.slice(1);
          return <article className="project-card" key={project.id}>
            <div className={`project-art tone-${tones[index % tones.length]}`}>
              <ProjectThumbnail project={project} />
              <span className="episode">EP {String(index + 1).padStart(2, "0")}</span>
              <span className="project-art-title">{project.title}</span>
              <button aria-label={`Preview ${project.title}`} onClick={() => onPreview(project)} type="button"><Play size={19} fill="currentColor" /></button>
              <span className={`status status-${project.status}`}>{label}</span>
            </div>
            <div className="project-info">
              <div><h3>{project.title}</h3><p>{project.language.toUpperCase()} · {project.aspect_ratio} · {project.current_stage}</p></div>
              <button aria-label={`Edit ${project.title}`} onClick={() => onOpenProject(project)} type="button"><ArrowUpRight size={18} /></button>
            </div>
            <div className="project-progress"><span style={{ width: `${project.progress}%` }} /></div>
          </article>;
        })}
      </div>
      {filtered.length === 0 ? <p className="empty-state">No productions match your search.</p> : null}
    </section>
  );
}
