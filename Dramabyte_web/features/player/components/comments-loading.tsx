import { Shimmer } from "@/components/loading/shimmer";

export function CommentsLoading() {
  return <div role="status" aria-label="Loading comments" aria-busy="true">{Array.from({ length: 4 }, (_, index) => <div key={index} style={{ display: "flex", gap: 12, marginBottom: 28 }}><Shimmer style={{ width: 36, height: 36, borderRadius: "50%", flexShrink: 0 }} /><div style={{ flex: 1 }}><Shimmer style={{ width: "45%", height: 12, marginBottom: 12 }} /><Shimmer style={{ height: 14, marginBottom: 8 }} /><Shimmer style={{ width: "70%", height: 14 }} /></div></div>)}</div>;
}
