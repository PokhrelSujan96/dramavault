import { useEffect, useState } from "react";
import { loadGeneration } from "@/lib/generation-cache";
import type { StoryProject } from "@/lib/project-types";

export function ProjectThumbnail({ project }: { project: StoryProject }) {
  const [source, setSource] = useState<string>();
  useEffect(() => {
    if (!["ready", "published", "review"].includes(project.status)) return;
    let active = true;
    void loadGeneration(project.id).then((result) => {
      if (active) setSource(result.published_url ?? result.preview_url ?? result.final_url);
    }).catch(() => {});
    return () => { active = false; };
  }, [project.id, project.status]);
  if (!source) return null;
  return <video className="project-thumbnail" src={`${source}#t=0.1`} preload="metadata" muted playsInline aria-hidden="true" />;
}
