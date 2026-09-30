import { Music2 } from "lucide-react";
import type { StoryProject } from "@/lib/project-types";

export function StudioAnalytics({ projects }: { projects: StoryProject[] }) {
  const ready = projects.filter((item) => ["ready", "published"].includes(item.status)).length;
  const completion = projects.length ? Math.round(ready / projects.length * 100) : 0;
  const days = Array.from({ length: 7 }, (_, index) => {
    const day = new Date();
    day.setDate(day.getDate() - 6 + index);
    return { label: day.toLocaleDateString("en", { weekday: "short" }), count: projects.filter((project) => new Date(project.created_at).toDateString() === day.toDateString()).length };
  });
  const max = Math.max(1, ...days.map((day) => day.count));
  const points = days.map((day, index) => `${20 + index * 120},${130 - day.count / max * 100}`).join(" ");
  return <section className="dashboard-overview">
    <article className="analytics-card">
      <div className="analytics-heading"><h2>Studio analytics</h2><a href="#recent-projects">View projects →</a></div>
      <p>Drama Studio activity over the last 7 days</p>
      <div className="analytics-summary"><span>Stories <b>{projects.length}</b></span><span>Ready <b>{ready}</b></span><span>Completion <b className="completion">{completion}%</b></span><span className="chart-legend">━ Activity</span></div>
      <svg viewBox="0 0 760 164" role="img" aria-label="Stories created during the last seven days">
        {[30, 63, 96, 130].map((y) => <line key={y} x1="20" x2="740" y1={y} y2={y} stroke="#e8ebea" strokeDasharray="3 5" />)}
        <polyline points={points} fill="none" stroke="#24332f" strokeWidth="2" />
        {days.map((day, index) => <g key={index}><circle cx={20 + index * 120} cy={130 - day.count / max * 100} r="3" fill="white" stroke="#24332f" strokeWidth="1.5" /><text x={20 + index * 120} y="158" textAnchor="middle" fill="#87938e" fontSize="9">{day.label}</text></g>)}
      </svg>
    </article>
    <article className="connector-card"><span className="soon-tag">SOON</span><span className="connector-icon"><Music2 size={20} /></span><h2>Studio Connector</h2><p>Publish finished dramas to connected channels<br />and social platforms</p></article>
  </section>;
}
