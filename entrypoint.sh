#!/usr/bin/env bash
set -euo pipefail

# Ensure PVC-backed user directories exist even when /home/dev is freshly mounted
mkdir -p \
  "${HOME}/.gemini" \
  "${HOME}/.local/bin" \
  "${HOME}/.local/share/mise/shims" \
  "${HOME}/.cache/uv" \
  "${HOME}/.config"

# Link image-managed environment profile as global Antigravity rule
ln -sfn /opt/antigravity/ENV_PROFILE.md "${HOME}/.gemini/GEMINI.md"

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

exec agy remote-control start
