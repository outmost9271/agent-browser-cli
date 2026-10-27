import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const packageRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const binDir = join(packageRoot, "bin");
const configFile = join(packageRoot, "config", "agent-browser.json");
const skillsDir = join(packageRoot, "agent-browser-skills");
const noLocalBrowser = join(binDir, "agent-browser-no-local");

const ENV_KEYS = [
  "PATH",
  "AGENT_BROWSER_CONFIG",
  "AGENT_BROWSER_EXECUTABLE_PATH",
  "AGENT_BROWSER_SKILLS_DIR",
] as const;

export default function (pi: ExtensionAPI) {
  let saved: Partial<Record<(typeof ENV_KEYS)[number], string | undefined>> | undefined;

  const apply = () => {
    if (saved) return;

    for (const path of [configFile, noLocalBrowser]) {
      if (!existsSync(path)) {
        console.warn(`[agent-browser-cli] missing required file: ${path}`);
      }
    }

    saved = {};
    for (const key of ENV_KEYS) saved[key] = process.env[key];

    const currentPath = process.env.PATH ?? "";
    if (!currentPath.split(":").includes(binDir)) {
      process.env.PATH = currentPath ? `${binDir}:${currentPath}` : binDir;
    }
    process.env.AGENT_BROWSER_CONFIG = configFile;
    process.env.AGENT_BROWSER_EXECUTABLE_PATH = noLocalBrowser;
    process.env.AGENT_BROWSER_SKILLS_DIR = skillsDir;
  };

  const restore = () => {
    if (!saved) return;
    for (const key of ENV_KEYS) {
      const value = saved[key];
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
    saved = undefined;
  };

  pi.on("session_start", apply);
  pi.on("session_shutdown", restore);
}
