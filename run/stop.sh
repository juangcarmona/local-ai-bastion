#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "${REPO_ROOT}/run/common.sh"

SERVICES=(router chat embed code)

if [[ $# -gt 0 ]]; then
  for svc in "$@"; do
    stop_one "$svc"
  done
  exit 0
fi

# default: stop all
for svc in "${SERVICES[@]}"; do
  stop_one "$svc"
done
