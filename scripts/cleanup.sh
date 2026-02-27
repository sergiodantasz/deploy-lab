#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/log.sh"

FORCE=false
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

cleanup_log "WARNING: This will remove ALL Docker containers, images, volumes, and unused networks on this machine, not only this project."
cleanup_log "It will also remove generated files for this project."
cleanup_log "Targets:"
cleanup_log "  - All Docker containers (running and stopped)"
cleanup_log "  - All Docker images"
cleanup_log "  - All Docker volumes"
cleanup_log "  - All unused Docker networks"
cleanup_log "  - Docker Compose services (dev and prod) with volumes"
cleanup_log "  - Nginx generated configs in nginx/conf.d/"
cleanup_log "  - Development TLS certs in nginx/certs/"
cleanup_log "  - Certbot data in certbot/"

if ! $FORCE; then
  printf "\nType 'yes' to DESTROY ALL DOCKER RESOURCES: "
  read -r answer
  if [[ "$answer" != "yes" ]]; then
    cleanup_log "Aborted by user."
    exit 0
  fi
fi

cleanup_log "Stopping and removing Docker Compose stacks (including volumes) for this project..."
(
  cd "$ROOT"

  if [[ -f "compose.yaml" && -f "compose.dev.yaml" ]]; then
    docker compose -f compose.yaml -f compose.dev.yaml down -v || true
  fi

  if [[ -f "compose.yaml" && -f "compose.prod.yaml" ]]; then
    docker compose -f compose.yaml -f compose.prod.yaml down -v || true
  fi
)

cleanup_log "Stopping all running Docker containers..."
docker stop $(docker ps -q) 2>/dev/null || true

cleanup_log "Removing all Docker containers..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

cleanup_log "Removing all Docker volumes..."
docker volume rm $(docker volume ls -q) 2>/dev/null || true

cleanup_log "Removing all Docker images..."
docker rmi -f $(docker images -aq) 2>/dev/null || true

cleanup_log "Pruning unused Docker networks..."
docker network prune -f 2>/dev/null || true

cleanup_log "Removing generated nginx configs..."
rm -rf "$ROOT/nginx/conf.d"

cleanup_log "Removing development self-signed TLS certificates..."
if ! rm -rf "$ROOT/nginx/certs" 2>/dev/null; then
  cleanup_log "Could not remove $ROOT/nginx/certs due to permissions. Run this script with sudo if you also want to delete those files."
fi

cleanup_log "Removing certbot data..."
rm -rf "$ROOT/certbot"

cleanup_log "Global Docker cleanup finished."
