"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { useRef } from "react";
import type { HomeTitle } from "@/domain/home/title";
import { homeSectionId } from "@/domain/home/section-id";
import { TitleCard } from "./title-card";
import styles from "./cards.module.css";

export function TitleRail({ title, items, portrait = false, genre = false }: { title: string; items: HomeTitle[]; portrait?: boolean; genre?: boolean }) {
  const rail = useRef<HTMLDivElement>(null);
  const move = (direction: number) => rail.current?.scrollBy({ left: direction * rail.current.clientWidth * .75, behavior: "smooth" });
  return <section className={styles.section} id={homeSectionId(title, genre)}><div className={styles.heading}><h2>{title}</h2><div className={styles.controls}><button aria-label={`Previous ${title}`} onClick={() => move(-1)}><ChevronLeft size={15} /></button><button aria-label={`Next ${title}`} onClick={() => move(1)}><ChevronRight size={15} /></button></div></div><div ref={rail} className={styles.rail}>{items.map((item) => <TitleCard key={item.id} item={item} portrait={portrait} />)}</div></section>;
}
