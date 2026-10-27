# agent-browser-cli

Pi package that puts the **agent-browser** Rust CLI on the `bash` tool `PATH`, forces a single bundled config file, and bundles the complete upstream skills.

Call it directly — no absolute path and no preflight checks:

```bash
agent-browser open https://example.com
```

## What is bundled

- `bin/agent-browser` — upstream prebuilt binary, v0.39.4, Linux x86_64 (glibc)
- `config/agent-browser.json` — the config the CLI reads
- `agent-browser-skills/` — complete upstream skills: 9 skills, 10 references, 3 templates
- `skills/agent-browser-cli/SKILL.md` — Pi-facing usage skill
- `extensions/agent-browser-cli.ts` — injects `PATH` and the two `AGENT_BROWSER_*` variables

## Install

```bash
pi install git:github.com/outmost9271/agent-browser-cli
```

Try it for one invocation:

```bash
pi -e ./agent-browser-cli
```

## How to change the CDP endpoint

### 1. Locate the config

The config lives inside the package:

```text
agent-browser-cli/
└── config/
    └── agent-browser.json      # edit cdp here
```

After installation, print its absolute path:

```bash
echo "$AGENT_BROWSER_CONFIG"
```

### 2. Edit `cdp`

Open it with any editor:

```bash
${EDITOR:-vi} "$AGENT_BROWSER_CONFIG"
```

Change only the `cdp` value and keep valid JSON:

```json
{
  "$schema": "https://agent-browser.dev/schema.json",
  "cdp": "http://192.168.1.10:9222",
  "pinTab": true
}
```

Accepted forms:

| Target | `cdp` value |
| --- | --- |
| Local default port | `"http://127.0.0.1:9222"` or `"9222"` |
| Another host | `"http://192.168.1.10:9222"` |
| Remote WebSocket | `"ws://host:9222/devtools/browser/<id>"` |
| Cloud browser | `"wss://browser-service.example/cdp?token=..."` |

### 3. Apply it

The next `agent-browser` command reads the new value. If the daemon is still attached to the old endpoint:

```bash
agent-browser close
```

Or use a new `--session`.

### 4. Verify

```bash
agent-browser open about:blank
```

Only if that fails, use the `curl` check in the next section.

### Notes

- `pi update` re-checks out the package and may overwrite this edit; set it again after upgrading.
- A `wss://` URL with a token is sensitive; do not commit or share it.
- Do not override it with `--cdp` on every command; the config file is the single entry point.

## When a command fails

Do not pre-check anything. Run `agent-browser` directly. If it fails, probe the configured endpoint with `curl`:

```bash
curl -sS --max-time 5 --noproxy '*' "http://host:port/json/version"
```

- No connection, no `webSocketDebuggerUrl` → the CDP endpoint is not available. Stop and report the endpoint and error to the user.
- `webSocketDebuggerUrl` present → the endpoint is up; keep debugging the CLI error.

## Full upstream skills

```bash
agent-browser skills list
agent-browser skills get core --full
agent-browser skills get electron
```

Files live in `agent-browser-skills/`.

## Layout

```text
agent-browser-cli/
├── package.json
├── extensions/agent-browser-cli.ts
├── bin/agent-browser
├── config/agent-browser.json      # CDP endpoint lives here
├── skills/agent-browser-cli/SKILL.md
├── agent-browser-skills/
├── LICENSE
└── NOTICE
```

## Updating the binary

Replace `bin/agent-browser` with the matching release from
<https://github.com/vercel-labs/agent-browser/releases>, keep it executable, and bump
the package version.

## License

Apache-2.0. The bundled binary and skills come from
[vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser); see `NOTICE`.
