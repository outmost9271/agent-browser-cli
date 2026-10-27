---
name: agent-browser-cli
description: 使用随包捆绑的 agent-browser Rust CLI 通过 CDP 操作浏览器。适用于打开网页、快照、点击、填表、截图、提取数据、多步自动化；包含配置位置、失败后的 curl 验证、完整上游 skills 和排错方法。
---

# agent-browser-cli

`agent-browser` 已由插件放入 Pi `bash` 工具的 `PATH`。**直接执行 `agent-browser`，不要使用绝对路径。**

启动任务前**不要**检查环境变量、`PATH`、版本或插件状态；直接运行需要的命令。

## 配置文件在插件中的位置

```text
agent-browser-cli/
└── config/
    └── agent-browser.json      ← CDP 端点在这里
```

安装后需要修改配置时，用下面的命令定位（这一步只在改配置时做，不要作为启动前检查）：

```bash
echo "$AGENT_BROWSER_CONFIG"
```

文件内容：

```json
{
  "$schema": "https://agent-browser.dev/schema.json",
  "cdp": "http://127.0.0.1:9222",
  "pinTab": true
}
```

把 `cdp` 改成实际可访问的 CDP 端点，支持 `9222`、`http://host:9222`、`ws://host:9222/devtools/browser/<id>`、`wss://service.example/cdp?token=...`。配置已固定，命令里不要再传 `--cdp`。

## 正常使用

```bash
agent-browser open https://example.com
agent-browser snapshot -i
agent-browser click @e3
agent-browser fill @e1 "text"
agent-browser snapshot -i
agent-browser screenshot --if-changed
agent-browser close
```

多 agent 共享同一浏览器时，用独立 `--session`；本包默认 `pinTab: true`。

## 仅在 agent-browser 失败后验证端点

只有当 `agent-browser` 命令失败（典型：CDP 连接失败）时才执行本节。不要提前验证。

1. 从配置读取端点：

```bash
endpoint=$(sed -n 's/.*"cdp"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$AGENT_BROWSER_CONFIG" | head -n 1)
printf '%s\n' "$endpoint"
```

2. 用 `curl` 验证端点：

```bash
# cdp 为 http://host:port 或纯端口时
curl -sS --max-time 5 --noproxy '*' "http://host:port/json/version"

# cdp 为 ws://host:port/... 时，把 ws 换成 http
# cdp 为 wss://... 时，把 wss 换成 https
```

3. 按结果处理：

| curl 结果 | 结论与动作 |
| --- | --- |
| 连接失败、超时、HTTP 错误，或响应中没有 `webSocketDebuggerUrl` | CDP **确实未开启或不可达**。立即停止任务，把端点和错误原文告诉用户；不要重试、不要换端口、不要启动本地浏览器、不要运行 install |
| 返回 `webSocketDebuggerUrl`，但 agent-browser 仍失败 | 端点在线；问题在参数、会话或 CLI，继续按错误信息排查 |

对 `wss://` 云服务，`/json/version` 可能不适用：只要 TLS/HTTP 有响应（包括 401、404）就说明网络可达，不要误判为未开启。

停止时向用户说明，例如：

```text
CDP 端点 http://192.168.1.10:9222 未开启或不可达：
curl 返回 Connection refused。请先在目标主机启动带 --remote-debugging-port=9222 的浏览器，或更新插件配置中的 cdp 后重试。
```

## 使用完整的 agent-browser skills

```bash
agent-browser skills list
agent-browser skills get core
agent-browser skills get core --full
agent-browser skills get dogfood
agent-browser skills get electron
agent-browser skills get slack
agent-browser skills get derive-client
agent-browser skills get vercel-sandbox
agent-browser skills get protected-vercel-deployments
agent-browser skills get agentcore
agent-browser skills get webmcp-gen
```

源文件在插件包的 `agent-browser-skills/`。

## 其他排错

| 现象 | 处理 |
| --- | --- |
| `Invalid CDP value` | 配置中的 `cdp` 只接受纯端口或完整 URL；`host:port` 要写成 `http://host:port` |
| `Skills directory not found` | 检查 `AGENT_BROWSER_SKILLS_DIR` 是否存在 |
| 命令连到旧端点 | daemon 会记住连接；`agent-browser close` 或使用新的 `--session` |
