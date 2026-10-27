#!/usr/bin/env bash
# Report whether the configured CDP endpoint looks local to this host.
# Usage: cdp-locality.sh [cdp-url]
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
default_config="$script_dir/../config/agent-browser.json"
config="${AGENT_BROWSER_CONFIG:-$default_config}"
target="${1:-}"

if [ -z "$target" ]; then
  if [ ! -f "$config" ]; then
    echo "endpoint= result=unknown reason=config-not-found config=$config"
    exit 2
  fi
  target=$(sed -n 's/.*"cdp"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$config" | head -n 1)
fi

if [ -z "$target" ]; then
  echo "endpoint= result=unknown reason=no-cdp-configured config=$config"
  exit 2
fi

rest="$target"
case "$rest" in
  *://*) rest="${rest#*://}" ;;
esac
authority="${rest%%/*}"
authority="${authority%%\?*}"
authority="${authority##*@}"

case "$authority" in
  \[*\]:*) host="${authority%%]*}"; host="${host#[}" ;;
  \[*\])   host="${authority#[}"; host="${host%]}" ;;
  *:*)     host="${authority%:*}" ;;
  *)       host="$authority" ;;
esac

# A bare value such as "9222" means localhost.
case "$host" in
  ''|*[!0-9]*) ;;
  *) host="127.0.0.1" ;;
esac

is_loopback() {
  case "$1" in
    localhost|localhost.localdomain|127.*|::1|0.0.0.0) return 0 ;;
    *) return 1 ;;
  esac
}

local_addrs=" 127.0.0.1 ::1 "
if command -v hostname >/dev/null 2>&1; then
  local_addrs="$local_addrs $(hostname -I 2>/dev/null || true) $(hostname -i 2>/dev/null || true) "
fi
if command -v ip >/dev/null 2>&1; then
  local_addrs="$local_addrs $(ip -o addr show 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | tr '\n' ' ')"
fi

if is_loopback "$host"; then
  echo "endpoint=$target host=$host result=local reason=loopback (may be an SSH/NAT forward)"
  exit 0
fi

local_hostnames=" $(hostname 2>/dev/null || true) $(hostname -f 2>/dev/null || true) "
case "$local_hostnames" in
  *" $host "*)
    echo "endpoint=$target host=$host result=local reason=local-hostname"
    exit 0
    ;;
esac

case " $local_addrs " in
  *" $host "*)
    echo "endpoint=$target host=$host result=local reason=local-interface"
    exit 0
    ;;
esac

if command -v getent >/dev/null 2>&1; then
  resolved=$(getent hosts "$host" 2>/dev/null | awk '{print $1}' | head -n 1 || true)
  if [ -n "$resolved" ]; then
    case " $local_addrs " in
      *" $resolved "*)
        echo "endpoint=$target host=$host result=local reason=resolves-to-local-address ip=$resolved"
        exit 0
        ;;
    esac
    echo "endpoint=$target host=$host result=remote reason=resolves-to-remote-address ip=$resolved"
    exit 1
  fi
fi

case "$host" in
  *[!0-9.]*)
    echo "endpoint=$target host=$host result=unknown reason=unresolved-hostname"
    exit 2
    ;;
  *)
    echo "endpoint=$target host=$host result=remote reason=remote-address"
    exit 1
    ;;
esac
