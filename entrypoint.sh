#!/usr/bin/env bash
# Starts gunicorn (Flask app) and cloudflared together in one container.
# Forwards SIGTERM/SIGINT to both children, waits for either to exit,
# then shuts the other down cleanly.

set -euo pipefail

APP_PORT="${APP_PORT:-8000}"
GUNICORN_WORKERS="${GUNICORN_WORKERS:-2}"

if [[ -z "${CLOUDFLARED_TOKEN:-}" ]]; then
  echo "[entrypoint] ERROR: CLOUDFLARED_TOKEN env var is required." >&2
  exit 1
fi

# Start Flask via gunicorn
gunicorn \
  --bind "0.0.0.0:${APP_PORT}" \
  --workers "${GUNICORN_WORKERS}" \
  --access-logfile - \
  --error-logfile - \
  app:app &
GUNICORN_PID=$!

# Start cloudflared tunnel pointing at the local app
cloudflared tunnel --no-autoupdate run --token "${CLOUDFLARED_TOKEN}" &
CLOUDFLARED_PID=$!

shutdown() {
  echo "[entrypoint] received signal, shutting down..."
  kill -TERM "${GUNICORN_PID}" "${CLOUDFLARED_PID}" 2>/dev/null || true
  wait "${GUNICORN_PID}" "${CLOUDFLARED_PID}" 2>/dev/null || true
  exit 0
}
trap shutdown SIGTERM SIGINT

# Exit if either child dies
wait -n "${GUNICORN_PID}" "${CLOUDFLARED_PID}"
EXIT_CODE=$?
echo "[entrypoint] a child process exited (code=${EXIT_CODE}), tearing down..."
shutdown
