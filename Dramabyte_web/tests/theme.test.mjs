import assert from "node:assert/strict";
import { test } from "node:test";
import { runInNewContext } from "node:vm";
import { load } from "./runtime-loader.mjs";

const { themeInit } = load("components/theme/theme-init.ts");
function initialize(value, systemLight, blocked = false) {
  const document = { documentElement: { dataset: {} } };
  runInNewContext(themeInit, {
    document,
    localStorage: { getItem: () => { if (blocked) throw new Error("Blocked"); return value; } },
    matchMedia: () => ({ matches: systemLight }),
  });
  return document.documentElement.dataset.theme;
}

test("saved theme wins over the system before rendering", () => {
  assert.equal(initialize("dark", true), "dark");
  assert.equal(initialize("light", false), "light");
});
test("new visitors and invalid preferences follow the system", () => {
  assert.equal(initialize(null, true), "light");
  assert.equal(initialize(null, false), "dark");
  assert.equal(initialize("unexpected", true), "light");
});
test("blocked browser storage does not prevent theme initialization", () => {
  assert.equal(initialize(null, true, true), "light");
  assert.equal(initialize(null, false, true), "dark");
});
