---
name: agent-browser-cli
description: 使用随包捆绑的 agent-browser Rust CLI，通过配置文件中的 CDP 端点操作浏览器。适用于打开网页、快照、点击、填表、截图、提取数据、多步自动化；包含完整上游 skills 和排错方法。
---

# agent-browser-cli

本插件把 `agent-browser`（Rust 单文件 CLI，v0.39.4）放到 Pi 的 `bash` 工具 `PATH` 中，并固定读取随包配置文件。

## 开始前先确认

```bash
agent-browser --version                 # 应输出 agent-browser 0.39.4
echo "$AGENT_BROWSER_CONFIG"            # 随包配置文件的绝对路径
echo "$AGENT_BROWSER_SKILLS_DIR"        # 随包完整 skills 目录
```

## 配置：只需要改这一个文件

端点写在 `$AGENT_BROWSER_CONFIG` 指向的 `agent-browser.json`：

```json
{
  "$schema": "https://agent-browser.dev/schema.json",
  "cdp": "http://127.0.0.1:9222",
  "pinTab": true
}
```

把 `cdp` 改成实际可访问的 CDP 端点，支持：

- `9222`（纯端口，按 `http://localhost:9222` 处理）
- `http://host:9222`
- `ws://host:9222/devtools/browser/<id>`
- `wss://browser-service.example/cdp?token=...`

改完后直接运行命令，无需每条都带 `--cdp`。连接失败时命令直接报错。

先用下面的命令确认端点可用：

```bash
curl -sS http://<host>:9222/json/version
```

应返回 `webSocketDebuggerUrl`。

## 使用完整的 agent-browser skills

随包包含上游全部 9 个 skill、10 篇 references、3 个模板：

```bash
agent-browser skills list
agent-browser skills get core             # 先读这个
agent-browser skills get core --full      # 含 references 与模板
agent-browser skills get dogfood
agent-browser skills get electron
agent-browser skills get slack
agent-browser skills get derive-client
agent-browser skills get vercel-sandbox
agent-browser skills get protected-vercel-deployments
agent-browser skills get agentcore
agent-browser skills get webmcp-gen
```

源文件在 `$AGENT_BROWSER_SKILLS_DIR`。

## 最小工作流

```bash
agent-browser open https://example.com
agent-browser snapshot -i                 # 交互元素 + @eN 引用
agent-browser click @e3
agent-browser fill @e1 "text"
agent-browser snapshot -i                 # 页面变化后重新快照
agent-browser screenshot --if-changed
agent-browser close
```

多 agent 共享同一 CDP 浏览器时，用独立 `--session`；本包默认 `pinTab: true`，避免互相抢标签页。

## 排错

| 现象 | 处理 |
| --- | --- |
| `Invalid CDP value` | `--cdp` 只接受纯端口或完整 URL；`host:port` 要写成 `http://host:port` |
| `All CDP discovery methods failed` | 端点不可达/端口未开；先 `curl http://host:port/json/version` |
| `Skills directory not found` | 检查 `AGENT_BROWSER_SKILLS_DIR` 是否存在 |
| 命令连到旧端点 | daemon 会记住连接；`agent-browser close` 或使用新的 `--session` |
