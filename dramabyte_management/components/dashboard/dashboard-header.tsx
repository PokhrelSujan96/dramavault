import { Sun, LogOut, Search } from "lucide-react";

type Props = {
  query: string;
  onQueryChange: (value: string) => void;
  onSignOut: () => Promise<void>;
};

export function DashboardHeader({ query, onQueryChange, onSignOut }: Props) {
  return (
    <header className="topbar">
      <label className="search-box">
        <Search size={18} />
        <input
          aria-label="Search productions"
          onChange={(event) => onQueryChange(event.target.value)}
          placeholder="Search by title..."
          value={query}
        />
        <kbd>⌘ K</kbd>
      </label>
      <div className="topbar-actions">
        <span className="theme-indicator" aria-label="White theme"><Sun size={20} /></span>
        <span className="workspace-label">Management <span>· Drama Studio</span></span>
        <button aria-label="Sign out" className="profile-button" onClick={() => void onSignOut()} type="button">
          <span className="avatar">S</span>
          <span className="profile-copy">
            <strong>Sujan Pokhrel</strong>
          </span>
          <LogOut size={15} />
        </button>
      </div>
    </header>
  );
}
