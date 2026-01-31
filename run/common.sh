#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env if present; always allow env override
if [[ -f "${REPO_ROOT}/.env" ]]; then
  # shellcheck disable=SC1090
  source "${REPO_ROOT}/.env"
fi

export LOG_DIR="${LOG_DIR:-${REPO_ROOT}/logs}"
export PID_DIR="${PID_DIR:-${REPO_ROOT}/.pids}"

mkdir -p "${LOG_DIR}" "${PID_DIR}"

# Minimal helpers
pid_file() { echo "${PID_DIR}/$1.pid"; }

is_running() {
  local name="$1"
  local pf; pf="$(pid_file "${name}")"
  [[ -f "${pf}" ]] || return 1
  local pid; pid="$(cat "${pf}")"
  [[ -n "${pid}" ]] || return 1
  kill -0 "${pid}" >/dev/null 2>&1
}

start_bg() {
  local name="$1"; shift
  local logfile="$1"; shift

  if is_running "${name}"; then
    echo "[skip] ${name} already running (pid $(cat "$(pid_file "${name}")"))"
    return 0
  fi

  echo "[start] ${name}"
  nohup "$@" >> "${logfile}" 2>&1 &
  echo $! > "$(pid_file "${name}")"
  echo "[ok] ${name} pid $!"
}

stop_one() {
  local name="$1"
  local pf; pf="$(pid_file "${name}")"
  if [[ ! -f "${pf}" ]]; then
    echo "[skip] ${name} no pidfile"
    return 0
  fi
  local pid; pid="$(cat "${pf}")"
  if [[ -z "${pid}" ]]; then
    rm -f "${pf}"
    echo "[skip] ${name} empty pidfile"
    return 0
  fi
  if kill -0 "${pid}" >/dev/null 2>&1; then
    echo "[stop] ${name} pid ${pid}"
    kill "${pid}" >/dev/null 2>&1 || true
    # give it a moment, then hard kill if needed
    for _ in {1..20}; do
      if kill -0 "${pid}" >/dev/null 2>&1; then
        sleep 0.2
      else
        break
      fi
    done
    if kill -0 "${pid}" >/dev/null 2>&1; then
      kill -9 "${pid}" >/dev/null 2>&1 || true
    fi
  else
    echo "[skip] ${name} pid ${pid} not running"
  fi
  rm -f "${pf}"
}

require_venv() {
  if [[ -z "${VENV_DIR:-}" ]]; then
    echo "[err] VENV_DIR not set. Define it in .env"
    exit 1
  fi

  if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
    echo "[err] venv missing at ${VENV_DIR}. Run: ./run/install.sh"
    exit 1
  fi

  # shellcheck disable=SC1090
  source "${VENV_DIR}/bin/activate"
}

require_env() {
  local key="$1"
  if [[ -z "${!key:-}" ]]; then
    echo "[err] missing env var: ${key}"
    exit 1
  fi
}
