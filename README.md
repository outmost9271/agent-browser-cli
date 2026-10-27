# agent-browser-cli

Pi package that puts the **agent-browser** Rust CLI on the `bash` tool `PATH`, forces a single bundled config file, and only allows browser automation over **CDP**. No local Chrome is ever launched.

## What is bundled

- `bin/agent-browser` — upstream prebuilt binary, v0.39.4, Linux x86_64 (glibc)
- `config/agent-browser.json` — the only config the CLI is allowed to read
- `agent-browser-skills/` — the complete upstream skills: 9 skills, 10 references, 3 templates
- `skills/agent-browser-cli/SKILL.md` — Pi-facing usage skill
- `extensions/agent-browser-cli.ts` — injects `PATH` and the required environment variables
- `scripts/cdp-locality.sh` — quick local-vs-remote endpoint check

## Install

```bash
pi install git:github.com/outmost9271/agent-browser-cli
```

Or try it for one invocation:

```bash
pi -e ./agent-browser-cli
```

## Configure the CDP endpoint

Find the bundled config path inside a Pi session:

```bash
echo "$AGENT_BROWSER_CONFIG"
```

Edit `cdp` in that file:

```json
{
  "$schema": "https://agent-browser.dev/schema.json",
  "cdp": "http://127.0.0.1:9222",
  "autoConnect": false,
  "pinTab": true
}
```

Accepted forms: `9222`, `http://host:9222`, `ws://host:9222/devtools/browser/<id>`, `wss://service.example/cdp?token=...`.

The extension sets `AGENT_BROWSER_CONFIG` to this file on every session start, so changing the file is enough. It also sets `AGENT_BROWSER_EXECUTABLE_PATH` to `bin/agent-browser-no-local`, a script that always exits with an error, so any accidental local launch fails immediately.

## Local vs remote browser

An endpoint spelled `127.0.0.1` does **not** prove the browser runs on the Pi host: SSH forwards, container port mappings, and NAT all look the same.

Quick check:

```bash
bash "$(dirname "$AGENT_BROWSER_SKILLS_DIR")/scripts/cdp-locality.sh"
bash "$(dirname "$AGENT_BROWSER_SKILLS_DIR")/scripts/cdp-locality.sh" "$(agent-browser get cdp-url)"
```

Reliable check: start a temporary HTTP server bound **only to `127.0.0.1`** on the Pi host, then let the browser open it:

```bash
mkdir -p /tmp/ab-probe && printf 'ok\n' > /tmp/ab-probe/index.html
busybox httpd -f -p 127.0.0.1:18999 -h /tmp/ab-probe &
probe_pid=$!

agent-browser open http://127.0.0.1:18999/
agent-browser get title     # success => browser shares the Pi loopback (local)
agent-browser close
kill "$probe_pid"
```

`ERR_CONNECTION_REFUSED` or a timeout means the browser is remote or in an isolated network namespace.

## What "CDP-only" does and does not guarantee

It prevents accidental local launches and keeps every command pointed at the configured endpoint. It is **not** a sandbox: explicit `--config`, `--cdp`, `--auto-connect`, `--provider`, `--executable-path`, `install`, `upgrade`, or `--engine` can still override it. Do not use those in this package's environment unless a task explicitly requires them.

## Full upstream skills

The CLI serves them directly:

```bash
agent-browser skills list
agent-browser skills get core --full
agent-browser skills get electron
```

Files live in `agent-browser-skills/` and `AGENT_BROWSER_SKILLS_DIR` points there.

## Layout

```text
agent-browser-cli/
├── package.json
├── extensions/agent-browser-cli.ts
├── bin/
│   ├── agent-browser
│   └── agent-browser-no-local
├── config/agent-browser.json
├── skills/agent-browser-cli/SKILL.md
├── agent-browser-skills/        # complete upstream docs
├── scripts/cdp-locality.sh
├── LICENSE
└── NOTICE
```

## Updating the binary

Replace `bin/agent-browser` with the matching official release from
<https://github.com/vercel-labs/agent-browser/releases>, keep it executable, and bump
the package version.

## License

Apache-2.0. The bundled binary and skills come from
[vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser); see `NOTICE`.
