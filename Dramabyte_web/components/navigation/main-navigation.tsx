"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Bookmark, ChevronDown, Film, Home, UserRound } from "lucide-react";
import { useEffect, useId, useRef, useState } from "react";
import { AccountPopover } from "@/features/account/components/account-popover";
import styles from "./main-navigation.module.css";

export function MainNavigation() {
  const pathname = usePathname();
  const [open, setOpen] = useState<"library" | "profile" | null>(null);
  const root = useRef<HTMLElement>(null);
  const trigger = useRef<HTMLButtonElement | null>(null);
  const panel = useRef<HTMLDivElement>(null);
  const id = useId();
  useEffect(() => {
    if (!open) return;
    panel.current?.focus({ preventScroll: true });
    const outside = (event: PointerEvent) => { if (!root.current?.contains(event.target as Node)) setOpen(null); };
    const escape = (event: KeyboardEvent) => { if (event.key === "Escape") { setOpen(null); trigger.current?.focus(); } };
    const focus = (event: FocusEvent) => { if (!root.current?.contains(event.target as Node)) setOpen(null); };
    document.addEventListener("pointerdown", outside);
    document.addEventListener("keydown", escape);
    document.addEventListener("focusin", focus);
    return () => {
      document.removeEventListener("pointerdown", outside);
      document.removeEventListener("keydown", escape);
      document.removeEventListener("focusin", focus);
    };
  }, [open]);
  return <nav ref={root} className={styles.nav} aria-label="Main navigation">
    <Link href="/" className={styles.item} onClick={() => setOpen(null)} aria-current={pathname === "/" ? "page" : undefined}><Home size={16} />Home</Link>
    <Link href="/discover" className={styles.item} onClick={() => setOpen(null)} aria-current={pathname === "/discover" ? "page" : undefined}><Film size={16} />Discover</Link>
    {(["library", "profile"] as const).map((name) => <div key={name} className={styles.anchor}>
      <button className={styles.item} aria-current={pathname === `/${name}` ? "page" : undefined} aria-expanded={open === name} aria-controls={`${id}-${name}`} aria-haspopup="dialog" onClick={(event) => { trigger.current = event.currentTarget; setOpen(open === name ? null : name); }}>{name === "library" ? <Bookmark size={16} /> : <UserRound size={16} />}{name === "library" ? "Library" : "Profile"}<ChevronDown size={12} className={open === name ? styles.rotate : ""} /></button>
      {open === name && <div ref={panel} id={`${id}-${name}`} className={`${styles.popover} ${name === "library" ? styles.libraryPopover : ""}`} role="dialog" aria-label={name === "library" ? "Library" : "Profile"} tabIndex={-1}><AccountPopover key={`${name}-${pathname}`} initial={name} onClose={() => { setOpen(null); trigger.current?.focus(); }} /></div>}
    </div>)}
  </nav>;
}
