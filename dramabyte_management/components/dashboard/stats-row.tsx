import { CheckCircle2, Clock3, Film, Zap } from "lucide-react";
import type { StoryProject } from "@/lib/project-types";

type Props = { projects: StoryProject[] };

export function StatsRow({ projects }: Props) {
  const active = projects.filter((item) => ["queued", "generating"].includes(item.status));
  const ready = projects.filter((item) => ["ready", "published"].includes(item.status));
  const average = projects.length
    ? Math.round(projects.reduce((total, item) => total + item.progress, 0) / projects.length)
    : 0;
  const stats = [
    [Film, String(projects.length), "Total stories", "Saved productions"],
    [Zap, String(active.length), "In production", active.length ? "Workers processing" : "Queue is clear"],
    [CheckCircle2, String(ready.length), "Ready to publish", "Completed masters"],
    [Clock3, `${average}%`, "Average progress", "Across all stories"],
  ] as const;
  return (
    <section className="stats-grid" aria-label="Production summary">
      {stats.map(([Icon, value, label, detail]) => (
        <article className="stat-card" key={label}>
          <span className="stat-icon"><Icon size={18} /></span>
          <div>
            <strong>{value}</strong>
            <p>{label}</p>
            <small>{detail}</small>
          </div>
        </article>
      ))}
    </section>
  );
}
