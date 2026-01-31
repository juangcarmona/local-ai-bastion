#!/usr/bin/env bash
set -euo pipefail

echo "[claude] Installing Claude Code (official)"

# Check node
if ! command -v node >/dev/null 2>&1; then
  echo "[err] Node.js is required. Install Node 18+ first."
  exit 1
fi

# Install Claude Code (official installer)
if command -v claude >/dev/null 2>&1; then
  echo "[ok] Claude already installed"
  claude --version || true
  exit 0
fi

echo "[claude] downloading installer"
curl -fsSL https://claude.ai/install.sh | bash

echo "[ok] Claude Code installed"
echo "Restart your shell if 'claude' is not found."
