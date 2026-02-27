#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$ROOT/.env" ]; then
  set -a
  . "$ROOT/.env"
  set +a
fi

CURRENT_ENV="${CURRENT_ENV:-development}"
BACKEND_SERVICE_NAME="${BACKEND_SERVICE_NAME:-deploy-lab}"
DOMAIN="${DOMAIN:-localhost}"

if [ "$CURRENT_ENV" = "development" ]; then
  ENV_DIR=dev
elif [ "$CURRENT_ENV" = "production" ]; then
  ENV_DIR=prod
else
  echo "[setup] CURRENT_ENV must be development or production, got: $CURRENT_ENV" >&2
  exit 1
fi

SRC="$ROOT/nginx/templates/${ENV_DIR}"
DEST="$ROOT/nginx/conf.d/${ENV_DIR}"

if [ ! -d "$SRC" ]; then
  echo "[setup] No templates for ${CURRENT_ENV}: ${SRC} not found" >&2
  exit 1
fi

mkdir -p "$DEST"

for f in "${SRC}"/*.conf; do
  [ -f "$f" ] || continue
  out="${DEST}/$(basename "$f")"
  while IFS= read -r line; do
    line="${line//\$\{BACKEND_SERVICE_NAME\}/$BACKEND_SERVICE_NAME}"
    line="${line//\$\{DOMAIN\}/$DOMAIN}"
    printf '%s\n' "$line"
  done < "$f" > "$out"
done

echo "[setup] Nginx: ${SRC} -> ${DEST}"
echo "[setup] Variables used: CURRENT_ENV=${CURRENT_ENV} BACKEND_SERVICE_NAME=${BACKEND_SERVICE_NAME} DOMAIN=${DOMAIN}"
