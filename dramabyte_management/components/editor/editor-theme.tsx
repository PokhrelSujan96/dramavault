"use client";

import { useSyncExternalStore } from "react";
import { Moon, Sun } from "lucide-react";

export type EditorTheme = "light" | "dark";

const preference = "dramabyte.editor.theme";

function subscribe(callback: () => void) {
  window.addEventListener("storage", callback);
  window.addEventListener("dramabyte-editor-theme", callback);
  return () => {
    window.removeEventListener("storage", callback);
    window.removeEventListener("dramabyte-editor-theme", callback);
  };
}

function currentTheme(): EditorTheme {
  return window.localStorage.getItem(preference) === "dark" ? "dark" : "light";
}

function updateTheme(theme: EditorTheme) {
  window.localStorage.setItem(preference, theme);
  window.dispatchEvent(new Event("dramabyte-editor-theme"));
}

export function useEditorTheme() {
  const theme = useSyncExternalStore<EditorTheme>(subscribe, currentTheme, () => "light");
  const toggle = () => {
    const next = theme === "light" ? "dark" : "light";
    updateTheme(next);
  };
  return { theme, toggle };
}

export function EditorThemeButton({ theme, onClick }: { theme: EditorTheme; onClick: () => void }) {
  const dark = theme === "dark";
  return <button aria-label={dark ? "Use light editor theme" : "Use dark editor theme"} aria-pressed={dark} className="editor-theme-button" onClick={onClick} title={dark ? "Light editor" : "Dark editor"} type="button">{dark ? <Sun size={17} /> : <Moon size={17} />}</button>;
}
