import fs from "node:fs";
import path from "node:path";
import ts from "typescript";
import { createRequire } from "node:module";

const nodeRequire = createRequire(import.meta.url);

export function load(file, context = {}, mocks = {}, cache = new Map()) {
  if (cache.has(file)) return cache.get(file);
  const loadedModule = { exports: {} };
  cache.set(file, loadedModule.exports);
  const code = ts.transpileModule(fs.readFileSync(path.resolve(file), "utf8"), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 },
  }).outputText;
  const requireModule = (name) => {
    if (name in mocks) return mocks[name];
    if (name === "server-only") return {};
    if (name.startsWith("@/")) return load(`${name.slice(2)}.ts`, context, mocks, cache);
    if (name.startsWith(".")) return load(path.join(path.dirname(file), `${name}.ts`), context, mocks, cache);
    return nodeRequire(name);
  };
  new Function("require", "module", "exports", ...Object.keys(context), code)(requireModule, loadedModule, loadedModule.exports, ...Object.values(context));
  return loadedModule.exports;
}

