#!/usr/bin/env bash
# manage.sh — build, start, stop, cleanup the personal site container.
#
# Designed to run on a Fedora server with Podman.
# Requires CLOUDFLARED_TOKEN in the environment (or in ./.env).
#
# Usage:
#   ./manage.sh build      # build the image
#   ./manage.sh start      # build (if needed) + run detached
#   ./manage.sh stop       # stop the running container
#   ./manage.sh restart    # stop + start
#   ./manage.sh logs       # follow container logs
#   ./manage.sh status     # show container status
#   ./manage.sh cleanup    # stop + remove container, image, and dangling layers

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-personalsite}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-personalsite}"
HOST_PORT="${HOST_PORT:-8000}"
APP_PORT="${APP_PORT:-8000}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Load .env if present (so CLOUDFLARED_TOKEN can live there)
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

require_token() {
  if [[ -z "${CLOUDFLARED_TOKEN:-}" ]]; then
    echo "ERROR: CLOUDFLARED_TOKEN is not set." >&2
    echo "Set it in your shell or in a .env file next to this script." >&2
    exit 1
  fi
}

cmd_build() {
  echo ">> Building ${IMAGE_NAME}:${IMAGE_TAG}"
  podman build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f Containerfile .
}

cmd_start() {
  require_token

  if podman container exists "${CONTAINER_NAME}"; then
    echo ">> Container '${CONTAINER_NAME}' already exists; removing first"
    podman rm -f "${CONTAINER_NAME}" >/dev/null
  fi

  if ! podman image exists "${IMAGE_NAME}:${IMAGE_TAG}"; then
    cmd_build
  fi

  echo ">> Starting ${CONTAINER_NAME} on host port ${HOST_PORT}"
  podman run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -p "${HOST_PORT}:${APP_PORT}" \
    -e "APP_PORT=${APP_PORT}" \
    -e "CLOUDFLARED_TOKEN=${CLOUDFLARED_TOKEN}" \
    "${IMAGE_NAME}:${IMAGE_TAG}"

  echo ">> Started. Use './manage.sh logs' to follow output."
}

cmd_stop() {
  if podman container exists "${CONTAINER_NAME}"; then
    echo ">> Stopping ${CONTAINER_NAME}"
    podman stop "${CONTAINER_NAME}" >/dev/null
    podman rm "${CONTAINER_NAME}" >/dev/null
    echo ">> Stopped and removed."
  else
    echo ">> Container '${CONTAINER_NAME}' is not running."
  fi
}

cmd_restart() {
  cmd_stop
  cmd_start
}

cmd_logs() {
  podman logs -f "${CONTAINER_NAME}"
}

cmd_status() {
  podman ps -a --filter "name=^${CONTAINER_NAME}$"
}

cmd_cleanup() {
  echo ">> Cleaning up container, image, and dangling layers"
  if podman container exists "${CONTAINER_NAME}"; then
    podman rm -f "${CONTAINER_NAME}" >/dev/null || true
  fi
  if podman image exists "${IMAGE_NAME}:${IMAGE_TAG}"; then
    podman rmi -f "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null || true
  fi
  podman image prune -f >/dev/null || true
  echo ">> Cleanup complete."
}

usage() {
  cat <<EOF
Usage: $0 {build|start|stop|restart|logs|status|cleanup}

Environment variables (override defaults):
  IMAGE_NAME       (default: personalsite)
  IMAGE_TAG        (default: latest)
  CONTAINER_NAME   (default: personalsite)
  HOST_PORT        (default: 8000)
  APP_PORT         (default: 8000)
  CLOUDFLARED_TOKEN  (required for 'start')

You can also place these in a .env file next to this script.
EOF
}

case "${1:-}" in
  build)   cmd_build ;;
  start)   cmd_start ;;
  stop)    cmd_stop ;;
  restart) cmd_restart ;;
  logs)    cmd_logs ;;
  status)  cmd_status ;;
  cleanup) cmd_cleanup ;;
  *)       usage; exit 1 ;;
esac
