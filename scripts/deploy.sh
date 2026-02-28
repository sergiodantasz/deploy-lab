#!/usr/bin/env bash

set -Eeuo pipefail

log() { printf '%s\n' "$*"; }
log_error() { printf '%b%s\n' $'\033[1;31m[ ERROR ]\033[0m ' "$*" >&2; }
log_success() { printf '%b%s\n' $'\033[1;32m[ SUCCESS ]\033[0m ' "$*"; }

catch_errors() {
  local rc=$?
  log_error "line=$LINENO rc=$rc cmd=$BASH_COMMAND"
  exit "$rc"
}

trap catch_errors ERR

APP_DIR="/deploy-lab"
BRANCH="main"

cd "$APP_DIR" || { log_error "cannot cd to $APP_DIR"; exit 1; }

if [[ ! -d .git ]]; then
  log_error "$APP_DIR is not a git repository"
  exit 1
fi

if ! command -v docker &>/dev/null; then
  log_error "docker not found"
  exit 1
fi

git fetch origin "$BRANCH"
git reset --hard "origin/$BRANCH"

if [[ ! -f compose.yaml && ! -f compose.prod.yaml && ! -f compose.dev.yaml ]]; then
  log_error "no compose.yaml, compose.prod.yaml or compose.dev.yaml in $APP_DIR"
  exit 1
fi

sudo docker compose up -d --build --remove-orphans

log_success "deployed $(git rev-parse --short HEAD)"
