# agent-browser.json

This is the config file that the bundled `agent-browser` CLI reads. The extension
forces `AGENT_BROWSER_CONFIG` to point here.

## How to change the CDP endpoint

1. Open this file (`agent-browser.json`).
2. Change the `cdp` value and keep valid JSON.
3. Save it.
4. If the daemon is still attached to the old endpoint, run `agent-browser close`
   or use a new `--session`.

Common values:

| Target | `cdp` value |
| --- | --- |
| Local default port | `"http://127.0.0.1:9222"` or `"9222"` |
| Another host | `"http://192.168.1.10:9222"` |
| Remote WebSocket | `"ws://host:9222/devtools/browser/<id>"` |
| Cloud browser | `"wss://browser-service.example/cdp?token=..."` |

Example:

```json
{
  "$schema": "https://agent-browser.dev/schema.json",
  "cdp": "http://192.168.1.10:9222"
}
```

Notes:

- `pi update` may overwrite this file; set `cdp` again after upgrading.
- Do not commit or share a `wss://` URL that contains a token.
