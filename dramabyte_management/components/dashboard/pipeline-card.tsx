import { ArrowRight, Check, LoaderCircle } from "lucide-react";
import type { StoryProject } from "@/lib/project-types";

const stages = [
  ["script", "Script", "DeepSeek V3"],
  ["storyboard", "Scenes", "Shot planner"],
  ["images", "Images", "FLUX.1 Schnell"],
  ["video", "Video", "Wan 2.1"],
  ["voice", "Voice", "Fish Audio S2.1"],
  ["render", "Master", "Whisper + FFmpeg"],
] as const;

type Props = { project?: StoryProject };

export function PipelineCard({ project }: Props) {
  const activeStage = project?.current_stage ?? "script";
  const activeIndex = stages.findIndex(([stage]) => stage === activeStage);

  return (
    <section className="pipeline-card">
      <div className="pipeline-copy">
        <span className="live-pill"><i /> {project ? "Live production" : "Pipeline ready"}</span>
        <h2>{project?.title ?? "No production is running"}</h2>
        <p>{project ? `${project.language.toUpperCase()} · ${project.aspect_ratio} · ${project.current_stage}` : "Start a saved story when you are ready."}</p>
      </div>
      <div className="pipeline-stages">
        {stages.map(([stage, title, provider], index) => {
          const status = project ? index < activeIndex ? "done" : index === activeIndex ? "active" : "queued" : "queued";
          return <div className={`stage ${status}`} key={stage}>
            <span className="stage-node">
              {status === "done" ? <Check size={14} /> : null}
              {status === "active" ? <LoaderCircle size={14} /> : null}
              {status === "queued" ? index + 1 : null}
            </span>
            <strong>{title}</strong>
            <small>{provider}</small>
            {index < stages.length - 1 ? <ArrowRight className="stage-arrow" size={16} /> : null}
          </div>;
        })}
      </div>
      <div className="pipeline-progress">
        <span style={{ width: `${project?.progress ?? 0}%` }} />
      </div>
      <div className="pipeline-meta">
        <span>{project ? `Current stage: ${project.current_stage}` : "Waiting for a production"}</span>
        <strong>{project?.progress ?? 0}%</strong>
      </div>
    </section>
  );
}
