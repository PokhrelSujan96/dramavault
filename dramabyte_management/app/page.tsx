"use client";

import { useState } from "react";
import { LoginScreen } from "@/components/auth/login-screen";
import { DashboardHeader } from "@/components/dashboard/dashboard-header";
import { PipelineCard } from "@/components/dashboard/pipeline-card";
import { Sidebar } from "@/components/dashboard/sidebar";
import { StoryStudio } from "@/components/studio/story-studio";
import { VideoEditor } from "@/components/editor/video-editor";
import { useProjects } from "@/hooks/use-projects";
import { apiRequest } from "@/lib/api-client";
import type { StoryProject } from "@/lib/project-types";
import { UsersPage } from "@/components/management/users-page";
import { VideosPage } from "@/components/management/videos-page";
import { SeriesPage } from "@/components/management/series-page";
import { clearQueries } from "@/lib/query-cache";
import { PlatformOverview } from "@/components/dashboard/platform-overview";
import { CommentsPage } from "@/components/management/comments-page";

export default function Home() {
  const [query, setQuery] = useState("");
  const [activePage, setActivePage] = useState("Dashboard");
  const [visitedPages, setVisitedPages] = useState(["Dashboard"]);
  const [editorProject, setEditorProject] = useState<StoryProject | null | undefined>();
  const [videoProject, setVideoProject] = useState<StoryProject>();
  const { projects, loading, authenticated, error, create, update, reload } = useProjects();

  if (loading) {
    return <main className="loading-screen"><span className="brand-mark">D</span><p>Opening production workspace...</p></main>;
  }

  if (!authenticated) return <LoginScreen onSuccess={reload} />;

  const signOut = async () => {
    await apiRequest("/auth/sign-out", { method: "POST" });
    clearQueries();
    await reload();
  };

  const preview = (project: StoryProject) => {
    if (["ready", "published"].includes(project.status)) setVideoProject(project);
    else setEditorProject(project);
  };

  return (
    <>
    <main className="app-shell" style={{ display: videoProject || editorProject !== undefined ? "none" : undefined }}>
      <Sidebar activePage={activePage} onNavigate={(page) => { setActivePage(page); setVisitedPages((pages) => pages.includes(page) ? pages : [...pages, page]); setQuery(""); }} onOpenStudio={() => setEditorProject(null)} />
      <section className="workspace">
        <DashboardHeader query={query} onQueryChange={setQuery} onSignOut={signOut} />
        <div className="content">
          {visitedPages.includes("Users") && <div hidden={activePage !== "Users"}><UsersPage query={activePage === "Users" ? query : ""} /></div>}
          {visitedPages.includes("Productions") && <div hidden={activePage !== "Productions"}><VideosPage query={activePage === "Productions" ? query : ""} onOpen={preview} /></div>}
          {visitedPages.includes("Series & episodes") && <div hidden={activePage !== "Series & episodes"}><SeriesPage query={activePage === "Series & episodes" ? query : ""} /></div>}
          {visitedPages.includes("Comments") && <div hidden={activePage !== "Comments"}><CommentsPage query={activePage === "Comments" ? query : ""} /></div>}
          <div hidden={activePage !== "Dashboard"}>
          <PlatformOverview query={query} onCreate={() => { setActivePage("Series & episodes"); setVisitedPages((pages) => pages.includes("Series & episodes") ? pages : [...pages, "Series & episodes"]); }} />
          {error ? <p className="dashboard-error">{error}</p> : null}
          {projects.some((project) => ["queued", "generating"].includes(project.status)) ? <PipelineCard project={projects.find((project) => ["queued", "generating"].includes(project.status))} /> : null}

          </div>
        </div>
      </section>
    </main>
    {videoProject && <VideoEditor onClose={() => { setVideoProject(undefined); void reload(); }} project={videoProject} />}
    {editorProject !== undefined && <StoryStudio project={editorProject ?? undefined} onClose={() => { setEditorProject(undefined); void reload(); }} onCreate={create} onUpdate={update} />}
    </>
  );
}
