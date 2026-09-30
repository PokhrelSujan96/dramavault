"use client";

import { useState } from "react";
import { AudioPanel } from "@/components/editor/audio-panel";
import { MusicPanel } from "@/components/editor/music-panel";
import { SoundEffectsPanel } from "@/components/editor/sound-effects-panel";
import { LanguagePanel, type HindiTrack } from "@/components/editor/language-panel";
import type { BackgroundMusic, SoundEffect } from "@/components/editor/editor-types";

type Props = {
  projectId: string;
  disabled: boolean;
  music: BackgroundMusic | null;
  onMusicChange: (music: BackgroundMusic | null) => void;
  onBusy: (busy: boolean) => void;
  onPrepare: () => Promise<void>;
  onComplete: () => Promise<void>;
  soundEffects: SoundEffect[];
  onSoundEffectsChange: (items: SoundEffect[]) => void;
  currentTime: number;
  localization?: HindiTrack | null;
  selectedLanguage: string;
  onLanguageChange: (language: "en" | "hi") => void;
};

export function EditorAudioPanel(props: Props) {
  const [tab, setTab] = useState<"music" | "voice" | "effects" | "languages">("music");
  return (
    <div className="editor-audio-panel">
      <nav className="audio-mode-tabs" aria-label="Audio tools">
        <button aria-pressed={tab === "music"} onClick={() => setTab("music")} type="button">Music</button>
        <button aria-pressed={tab === "effects"} onClick={() => setTab("effects")} type="button">Effects</button>
        <button aria-pressed={tab === "voice"} onClick={() => setTab("voice")} type="button">Narration</button>
        <button aria-pressed={tab === "languages"} onClick={() => setTab("languages")} type="button">Languages</button>
      </nav>
      <div className="audio-mode-content" hidden={tab !== "music"}>
        <MusicPanel onChange={props.onMusicChange} projectId={props.projectId} value={props.music} />
      </div>
      <div className="audio-mode-content" hidden={tab !== "voice"}>
        <AudioPanel disabled={props.disabled} onBusy={props.onBusy} onComplete={props.onComplete} onPrepare={props.onPrepare} projectId={props.projectId} />
      </div>
      <div className="audio-mode-content" hidden={tab !== "effects"}>
        <SoundEffectsPanel currentTime={props.currentTime} onChange={props.onSoundEffectsChange} value={props.soundEffects} />
      </div>
      {tab === "languages" ? <div className="audio-mode-content"><LanguagePanel disabled={props.disabled} onBusy={props.onBusy} onComplete={props.onComplete} onSelect={props.onLanguageChange} projectId={props.projectId} selectedLanguage={props.selectedLanguage} track={props.localization} /></div> : null}
    </div>
  );
}
