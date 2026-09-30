import {
  Clapperboard,
  FolderOpen,
  LayoutDashboard,
  Sparkles,
  Users,
  MessageCircle,
} from "lucide-react";

const items = [
  [LayoutDashboard, "Dashboard"],
  [Sparkles, "Story studio"],
  [Clapperboard, "Productions"],
  [FolderOpen, "Series & episodes"],
  [Users, "Users"],
  [MessageCircle, "Comments"],
] as const;

type Props = {
  onOpenStudio: () => void;
  activePage: string;
  onNavigate: (page: string) => void;
};

export function Sidebar({ onOpenStudio, activePage, onNavigate }: Props) {
  return (
    <aside className="sidebar">
      <div className="brand">
        <span>DRAMABYTE</span>
      </div>
      <nav aria-label="Management navigation">
        {items.map(([Icon, label]) => (
          <button
            className={activePage === label ? "nav-item active" : "nav-item"}
            key={label}
            onClick={() => label === "Story studio" ? onOpenStudio() : onNavigate(label)}
            type="button"
          >
            <Icon size={18} strokeWidth={1.8} />
            <span>{label}</span>
          </button>
        ))}
      </nav>
      <div className="sidebar-foot">
        <span>DramaByte Management</span>
      </div>
    </aside>
  );
}
