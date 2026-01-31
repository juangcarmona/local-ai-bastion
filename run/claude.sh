#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "${REPO_ROOT}/.env"

if [[ ! -d "${CLAUDE_VENV_DIR}" ]]; then
  echo "[err] Claude venv not found. Run ./run/install-claude.sh first."
  exit 1
fi

# shellcheck disable=SC1090
source "${CLAUDE_VENV_DIR}/bin/activate"

export OPENAI_BASE_URL="${CLAUDE_OPENAI_BASE_URL}"
export OPENAI_API_KEY="${CLAUDE_OPENAI_API_KEY}"
export OPENAI_MODEL="${CLAUDE_OPENAI_MODEL}"

exec claude "$@"
