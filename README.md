# agent-browser-cli

Pi package that puts the **agent-browser** Rust CLI on the `bash` tool `PATH`, forces a single bundled config file, and bundles the complete upstream skills.

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

## Configure the CDP endpoint

Inside a Pi session:

```bash
echo "$AGENT_BROWSER_CONFIG"
```

Edit `cdp` in that file:

```json
{
  "$schema": "https://agent-browser.dev/schema.json",
  "cdp": "http://127.0.0.1:9222",
  "pinTab": true
}
```

Accepted forms: `9222`, `http://host:9222`, `ws://host:9222/devtools/browser/<id>`, `wss://service.example/cdp?token=...`.

The extension sets `AGENT_BROWSER_CONFIG` and `AGENT_BROWSER_SKILLS_DIR` at session start, so editing the file is all that is needed.

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
├── config/agent-browser.json
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
