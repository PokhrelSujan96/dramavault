"use client";

import { FormEvent, useState } from "react";
import { ArrowLeft, LoaderCircle, Play, Save, Sparkles } from "lucide-react";
import { apiRequest } from "@/lib/api-client";
import type { ProjectDraft, StoryProject } from "@/lib/project-types";
import { HybridProduction } from "./hybrid-production";
import { DialoguePilotWorkspace } from "./dialogue-pilot-workspace";
import { SchoolStoryPreset } from "./school-story-preset";
import { NarratorSettings } from "./narrator-settings";
import { StudioCharacterSetup } from "./studio-character-setup";
import type { HybridState } from "./hybrid-types";

type Props = {
  project?: StoryProject;
  onClose: () => void;
  onCreate: (draft: ProjectDraft) => Promise<StoryProject>;
  onUpdate: (projectId: string, draft: ProjectDraft) => Promise<StoryProject>;
};

const emptyDraft: ProjectDraft = {
  title: "",
  premise: "",
  script: "",
  language: "en",
  aspect_ratio: "9:16",
};

export function StoryStudio({ project, onClose, onCreate, onUpdate }: Props) {
  if (project?.production_mode === "dialogue_pilot") return <DialoguePilotWorkspace projectId={project.id} onClose={onClose} />;
  return <NarrationStudio project={project} onClose={onClose} onCreate={onCreate} onUpdate={onUpdate} />;
}

function NarrationStudio({ project, onClose, onCreate, onUpdate }: Props) {
  const initialDraft = project ? {
    title: project.title,
    premise: project.premise,
    script: project.script,
    language: project.language,
    aspect_ratio: project.aspect_ratio,
  } : emptyDraft;
  const [draft, setDraft] = useState(initialDraft);
  const [duration, setDuration] = useState(60);
  const [busy, setBusy] = useState<"script" | "save" | "start" | "">("");
  const [saved, setSaved] = useState<StoryProject | null>(project ?? null);
  const [dirty, setDirty] = useState(false);
  const [message, setMessage] = useState("");
  const [productionVersion, setProductionVersion] = useState(0);

  const change = (key: keyof ProjectDraft, value: string) => {
    setDraft((current) => ({ ...current, [key]: value }));
    setDirty(true);
  };

  const generateScript = async () => {
    if (draft.premise.trim().length < 20) {
      setMessage("Add a premise of at least 20 characters first.");
      return;
    }
    setBusy("script");
    setMessage("");
    try {
      const result = await apiRequest<{ script: string }>("/generation/script", {
        method: "POST",
        body: { premise: draft.premise, language: draft.language, duration_seconds: duration },
      });
      change("script", result.script);
      setMessage("Script generated. Review it before saving.");
    } catch (cause) {
      setMessage(cause instanceof Error ? cause.message : "Script generation failed");
    } finally {
      setBusy("");
    }
  };

  const save = async (event?: FormEvent) => {
    event?.preventDefault();
    setBusy("save");
    setMessage("");
    try {
      const result = saved
        ? await onUpdate(saved.id, draft)
        : await onCreate(draft);
      setSaved(result);
      setDirty(false);
      setMessage("Draft saved safely.");
      setProductionVersion((value) => value + 1);
    } catch (cause) {
      setMessage(cause instanceof Error ? cause.message : "Unable to save draft");
    } finally {
      setBusy("");
    }
  };

  const start = async () => {
    if (!saved) return;
    try {
      const context = await apiRequest<HybridState>(`/generation/project/${saved.id}/hybrid`);
      if (!context.series_id) { setMessage("Assign this draft to a series first."); return; }
      const names = context.characters.map((person) => person.name.toLowerCase());
      const required = draft.title.includes("The Girl in the Last Seat") ? ["Ellie", "Mia", "Claire", "Ms Reed"] : [];
      const missing = required.filter((name) => !names.includes(name.toLowerCase()));
      if (!names.length || missing.length) {
        setMessage(`Upload approved portraits in Step 1 below: ${missing.length ? missing.join(", ") : "your story characters"}. No credits have been spent.`);
        document.getElementById("studio-characters")?.scrollIntoView({ behavior: "smooth" });
        return;
      }
    } catch (cause) {
      setMessage(cause instanceof Error ? cause.message : "Unable to check character setup");
      return;
    }
    if (!window.confirm("Generate the storyteller audio, shared school sets and storyboard keyframes using paid provider credits? Motion generation remains gated by your keyframe approvals.")) return;
    setBusy("start");
    setMessage("");
    try {
      await apiRequest("/generation/start", {
        method: "POST",
        body: { project_id: saved.id },
        idempotencyKey: crypto.randomUUID(),
      });
      setMessage("Production queued. You can return to the dashboard.");
      setProductionVersion((value) => value + 1);
    } catch (cause) {
      setMessage(cause instanceof Error ? cause.message : "Unable to queue production");
    } finally {
      setBusy("");
    }
  };

  return (
    <main className="studio-page">
      <header className="studio-header">
        <button className="back-button" onClick={onClose} type="button"><ArrowLeft size={17} /> Dashboard</button>
        <div><strong>Story Studio</strong><span>{dirty ? "Unsaved changes" : saved ? "Draft saved" : "New draft"}</span></div>
        <button className="save-button" disabled={Boolean(busy)} form="story-form" type="submit"><Save size={16} /> Save draft</button>
      </header>
      {!saved && <SchoolStoryPreset onPrepared={(prepared) => {
        setSaved(prepared);
        setDraft({ title: prepared.title, premise: prepared.premise, script: prepared.script, language: prepared.language, aspect_ratio: prepared.aspect_ratio });
        setDirty(false);
        setDuration(90);
        setMessage("Series and Episode 1 created. Add the four character portraits in Series management, then start production.");
      }} />}
      <form className="studio-layout" id="story-form" onSubmit={save}>
        <section className="story-form">
          <div className="studio-title"><p className="eyebrow">Editorial input</p><h1>{project ? "Edit your drama" : "Create a new drama"}</h1><p>Shape the narration and production settings before generating media.</p></div>
          <label>Story title<input maxLength={160} onChange={(event) => change("title", event.target.value)} placeholder="The Last Train Home" required value={draft.title} /></label>
          <label>Premise<textarea maxLength={2000} onChange={(event) => change("premise", event.target.value)} placeholder="Describe the characters, conflict, setting, and emotional ending..." required rows={7} value={draft.premise} /></label>
          <div className="script-heading"><label htmlFor="script">Narration script</label><button disabled={Boolean(busy)} onClick={generateScript} type="button"><Sparkles size={15} /> {busy === "script" ? "Writing..." : "Generate with AI"}</button></div>
          <textarea id="script" maxLength={50000} onChange={(event) => change("script", event.target.value)} placeholder="Write your own narration or generate a first draft..." required rows={15} value={draft.script} />
          <span className="character-count">{draft.script.length.toLocaleString()} characters</span>
          {saved && !dirty && <HybridProduction key={saved.id} projectId={saved.id} refreshKey={productionVersion} onQueued={() => setMessage("Approved production queued.")} />}
        </section>
        <aside className="production-settings">
          <div><p className="eyebrow">Output plan</p><h2>Production settings</h2></div>
          <NarratorSettings school={draft.title.includes("The Girl in the Last Seat")} />
          <label>Language<select onChange={(event) => change("language", event.target.value)} value={draft.language}><option value="en">English</option><option value="ne">Nepali</option><option value="hi">Hindi</option></select></label>
          <label>Target duration<select onChange={(event) => setDuration(Number(event.target.value))} value={duration}><option value={30}>30 seconds</option><option value={60}>60 seconds</option><option value={90}>90 seconds</option><option value={120}>2 minutes</option></select></label>
          <label>Frame<select onChange={(event) => change("aspect_ratio", event.target.value)} value={draft.aspect_ratio}><option value="9:16">Portrait 9:16 · 1080 × 1920 finish</option></select></label>
          <div className="cost-note"><strong>Accurate story footage</strong><p>Start production generates the configured Fish voice, locally aligns the spoken words, then plans and checks each scene. Approve location, action and identity before generating video for every shot. No still images appear in the final timeline.</p></div>
          {message ? <p className="studio-message">{message}</p> : null}
          <button className="start-button" disabled={!saved || dirty || Boolean(busy)} onClick={start} type="button">{busy === "start" ? <LoaderCircle className="spin" size={17} /> : <Play size={17} fill="currentColor" />} Start production</button>
        </aside>
      </form>
      {saved && <div id="studio-characters"><StudioCharacterSetup projectId={saved.id} school={draft.title.includes("The Girl in the Last Seat")} /></div>}
    </main>
  );
}
