#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "${REPO_ROOT}/run/common.sh"

show_one() {
  local name="$1"
  local pf; pf="$(pid_file "${name}")"
  if is_running "${name}"; then
    echo "[up]   ${name} pid $(cat "${pf}")"
  else
    if [[ -f "${pf}" ]]; then
      echo "[down] ${name} stale pidfile $(cat "${pf}")"
    else
      echo "[down] ${name}"
    fi
  fi
}

show_one "code"
show_one "embed"
show_one "chat"
show_one "router"
