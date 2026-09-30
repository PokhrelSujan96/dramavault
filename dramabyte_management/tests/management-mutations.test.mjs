import { registerHooks } from "node:module";
import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { clearQueries, setQuery, snapshot } from "../lib/query-cache.ts";

registerHooks({ resolve(specifier, context, next) {
  if (specifier.startsWith("@/")) return next(new URL(`../${specifier.slice(2)}.ts`, import.meta.url).href, context);
  if (context.parentURL?.endsWith(".ts") && specifier.startsWith(".") && !specifier.endsWith(".ts")) return next(`${specifier}.ts`, context);
  return next(specifier, context);
} });
const { optimisticChange, writeManagement } = await import("../lib/optimistic-management.ts");
beforeEach(() => clearQueries());

test("coin changes immediately update the list, profile and ledger and can roll back", () => {
  const user = { id: "user", coins: 10 };
  setQuery("/admin/users?page=1", { items: [user] });
  setQuery("/admin/users/user", { profile: user, transactions: [] });
  const change = optimisticChange("/admin/users/user/coins", "POST", { amount: 5, reason: "Bonus" });
  assert.equal(snapshot("/admin/users?page=1").data.items[0].coins, 15);
  assert.equal(snapshot("/admin/users/user").data.profile.coins, 15);
  assert.equal(snapshot("/admin/users/user").data.transactions.length, 1);
  change.rollback();
  assert.equal(snapshot("/admin/users/user").data.profile.coins, 10);
  assert.equal(snapshot("/admin/users/user").data.transactions.length, 0);
});

test("publishing updates both the dashboard and video list", () => {
  setQuery("/projects", { items: [{ id: "video", status: "ready" }] });
  setQuery("/admin/videos?page=1", { items: [{ id: "video", status: "ready" }] });
  optimisticChange("/admin/videos/video", "PATCH", { status: "published" });
  assert.equal(snapshot("/projects").data.items[0].status, "published");
  assert.equal(snapshot("/admin/videos?page=1").data.items[0].status, "published");
});

test("rejected deletes restore the visible record", async () => {
  setQuery("/admin/videos?page=1", { items: [{ id: "video" }], total: 1 });
  const fetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({ detail: "Rejected" }), { status: 409 });
  try {
    await assert.rejects(writeManagement("/admin/videos/video", "DELETE"), /Rejected/);
    assert.equal(snapshot("/admin/videos?page=1").data.items.length, 1);
    assert.equal(snapshot("/admin/videos?page=1").data.total, 1);
  } finally { globalThis.fetch = fetch; }
});

test("new series use the confirmed server identifier after saving", async () => {
  setQuery("/admin/series", { items: [], total: 0 });
  const fetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({ id: "confirmed", title: "New series" }), { status: 201 });
  try {
    await writeManagement("/admin/series", "POST", { title: "New series" });
    assert.equal(snapshot("/admin/series").data.items[0].id, "confirmed");
    assert.equal(snapshot("/admin/series").data.total, 1);
  } finally { globalThis.fetch = fetch; }
});
