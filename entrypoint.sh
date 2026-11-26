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

shutdown() {
  echo "[entrypoint] Stopping remote-control daemon..."
  agy remote-control stop >/dev/null 2>&1 || true
  exit 0
}
trap shutdown SIGTERM SIGINT

if agy remote-control start; then
  echo "[entrypoint] Remote-control daemon started; entering monitor loop."
  while agy remote-control status >/dev/null 2>&1; do
    sleep 15 &
    wait $!
  done
  echo "[entrypoint] Remote-control daemon is no longer running." >&2
  exit 1
else
  echo "[entrypoint] 'agy remote-control start' failed (likely unauthenticated on first boot)." >&2
  echo "[entrypoint] Keeping container alive so you can 'kubectl exec -it' in to run 'agy' login." >&2
  while true; do
    sleep 30 &
    wait $!
  done
fi
