---
name: agent-browser-cli
description: 使用随包捆绑的 agent-browser Rust CLI 通过远程 CDP 端点操作浏览器。适用于打开网页、快照、点击、填表、截图、提取数据、多步自动化；包含 CDP-only 配置、本机/远程判定、完整上游 skills 和排错方法。
---

# agent-browser-cli

本插件把 `agent-browser`（Rust 单文件 CLI，v0.39.4）放到 Pi 的 `bash` 工具 `PATH` 中，并强制使用随包配置文件。**只允许 CDP 连接，禁止启动本地 Chrome。**

## 开始前先确认

```bash
agent-browser --version                 # 应输出 agent-browser 0.39.4
echo "$AGENT_BROWSER_CONFIG"            # 随包配置文件的绝对路径
echo "$AGENT_BROWSER_SKILLS_DIR"        # 随包完整 skills 目录
```

如果 `agent-browser` 不在 `PATH`，说明扩展未加载或当前不是 Pi 会话；不要自行下载或安装浏览器。

## 配置：只能改这一个文件

端点写在 `$AGENT_BROWSER_CONFIG` 指向的 `agent-browser.json`：

```json
{
  "$schema": "https://agent-browser.dev/schema.json",
  "cdp": "http://127.0.0.1:9222",
  "autoConnect": false,
  "pinTab": true
}
```

把 `cdp` 改成实际可访问的 CDP 端点，支持：

- `9222`（纯端口，按 `http://localhost:9222` 处理）
- `http://host:9222`
- `ws://host:9222/devtools/browser/<id>`
- `wss://browser-service.example/cdp?token=...`

改完后直接运行命令，无需每条都带 `--cdp`。会话会保持附加到该端点，直到 `agent-browser close`；端点不可达时命令直接报错，**不会回退到本地浏览器**。

不要把 `cdp` 指向浏览器未开启调试端口的主机；先用：

```bash
curl -sS http://<host>:9222/json/version
```

确认返回 `webSocketDebuggerUrl`。

## CDP-only 是怎么保证的

扩展在会话启动时注入：

| 变量 | 作用 |
| --- | --- |
| `PATH` | 加入随包 `bin/`，使 `agent-browser` 可直接调用 |
| `AGENT_BROWSER_CONFIG` | 强制读取随包 `config/agent-browser.json` |
| `AGENT_BROWSER_EXECUTABLE_PATH` | 指向一个必定失败的占位程序，任何本地启动都会报错 |
| `AGENT_BROWSER_SKILLS_DIR` | 指向随包完整上游 skills |

这是**防误操作**，不是安全沙箱：显式 `--config`、`--cdp`、`--auto-connect`、`--provider`、`--executable-path` 仍可覆盖。除非任务明确要求，不要使用这些参数。

也不要在本插件环境中运行 `agent-browser install`、`upgrade`，或指定 `--engine lightpanda|obscura`。

## 判断浏览器在本机还是远端

端点写作 `127.0.0.1` **不代表**浏览器运行在 Pi 主机：SSH 端口转发、容器端口映射、NAT 都会造成这种表象。按以下顺序判断。

### 方法 A：解析端点（快速初判）

```bash
bash "$(dirname "$AGENT_BROWSER_SKILLS_DIR")/scripts/cdp-locality.sh"
# 或连接后传入实际 WebSocket URL
agent-browser get cdp-url
bash "$(dirname "$AGENT_BROWSER_SKILLS_DIR")/scripts/cdp-locality.sh" "ws://..."
```

输出 `result=local|remote|unknown`：

- `local`：端点是回环地址、本机网卡地址，或解析到本机地址
- `remote`：端点属于其他主机
- `unknown`：无法解析

脚本把回环端点也标为 `local`，但会在 `reason` 中注明可能是转发。

### 方法 B：查看实际连接

```bash
agent-browser get cdp-url
```

返回浏览器实际使用的 `ws://` / `wss://` 地址。再交给方法 A 判断。它同样无法区分端口转发。

### 方法 C：回环服务探测（可靠）

在 Pi 主机启动一个**只监听 `127.0.0.1`** 的临时 HTTP 服务，然后让浏览器访问它：

```bash
mkdir -p /tmp/ab-probe && printf 'ok\n' > /tmp/ab-probe/index.html
busybox httpd -f -p 127.0.0.1:18999 -h /tmp/ab-probe &
probe_pid=$!

agent-browser open http://127.0.0.1:18999/
agent-browser get title        # 成功返回页面标题 => local
agent-browser close
kill "$probe_pid"
```

判断：

- 页面能打开 → 浏览器与 Pi 共享回环网络，**本机**
- `ERR_CONNECTION_REFUSED` / 超时 → 浏览器在**远端**或隔离的网络命名空间

原理：`127.0.0.1` 在浏览器所在主机解析。只有浏览器进程与 Pi 主机共享同一回环时，才能访问到 Pi 上的临时服务。SSH 转发不会让这一步误判。

没有 `busybox` 时，可用任意仅绑定 `127.0.0.1` 的临时 HTTP 服务替代；不要绑定 `0.0.0.0`。

### 判定结论怎么用

- **本机**：页面里的 `localhost`、`file://` 路径、下载目录通常指 Pi 主机
- **远端**：页面里的 `localhost` 指浏览器主机；`upload` 的文件路径也在浏览器/CLI 宿主侧解析；不要假设能看到 Pi 的本地窗口或文件

## 使用完整的 agent-browser skills

随包包含上游全部 9 个 skill 和 10 篇 references、3 个模板：

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

多 agent 共享同一远程浏览器时，用独立 `--session`；本包已默认 `pinTab: true`，避免互相抢标签页。

## 排错

| 现象 | 处理 |
| --- | --- |
| `Invalid CDP value` | `--cdp` 只接受纯端口或完整 URL；`host:port` 要写成 `http://host:port` |
| `All CDP discovery methods failed` | 端点不可达/端口未开；先 `curl http://host:port/json/version` |
| `Chrome exited early ...` | 有代码在尝试本地启动；检查是否误传 `--auto-connect` / `--provider` / `--executable-path` |
| `Skills directory not found` | 检查 `AGENT_BROWSER_SKILLS_DIR` 是否存在 |
| 命令连到旧端点 | daemon 会记住连接；`agent-browser close` 或使用新的 `--session` |

不要用 `agent-browser doctor` 的本地 Chrome 检查作为本插件健康标准：本插件不使用本地浏览器。
