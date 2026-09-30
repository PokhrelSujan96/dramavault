"use client";

import { Moon, Sun } from "lucide-react";
import { useEffect, useSyncExternalStore } from "react";
import styles from "./theme-toggle.module.css";

const key = "dramabyte-theme";
const subscribe = (listener: () => void) => {
  window.addEventListener("dramabyte-theme-change", listener);
  return () => window.removeEventListener("dramabyte-theme-change", listener);
};
const snapshot = () => document.documentElement.dataset.theme === "light" ? "light" : "dark";
const serverSnapshot = () => "dark" as const;
const preference = () => {
  try { const value = localStorage.getItem(key); return value === "light" || value === "dark" ? value : null; }
  catch { return null; }
};
const apply = (theme: "light" | "dark") => {
  document.documentElement.dataset.theme = theme;
  window.dispatchEvent(new Event("dramabyte-theme-change"));
};

export function ThemeToggle() {
  const theme = useSyncExternalStore(subscribe, snapshot, serverSnapshot);
  useEffect(() => {
    const media = window.matchMedia("(prefers-color-scheme: light)");
    const sync = () => apply(preference() ?? (media.matches ? "light" : "dark"));
    const storage = (event: StorageEvent) => { if (event.key === key || event.key === null) sync(); };
    sync();
    media.addEventListener("change", sync);
    window.addEventListener("storage", storage);
    return () => { media.removeEventListener("change", sync); window.removeEventListener("storage", storage); };
  }, []);
  const toggle = () => {
    const next = theme === "dark" ? "light" : "dark";
    try { localStorage.setItem(key, next); } catch {}
    apply(next);
  };
  return <button type="button" className={styles.toggle} onClick={toggle} aria-label={`Switch to ${theme === "dark" ? "light" : "dark"} theme`} title={`Switch to ${theme === "dark" ? "light" : "dark"} theme`}>{theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}</button>;
}
