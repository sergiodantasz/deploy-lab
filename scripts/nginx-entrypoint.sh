#!/bin/sh

set -eu

: "${CURRENT_ENV:?"CURRENT_ENV not defined."}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/log.sh"

if [ "$CURRENT_ENV" = "development" ]; then
  DOMAIN="${DOMAIN:-localhost}"

  CERT_DIR="/etc/nginx/certs"
  CRT="${CERT_DIR}/dev.crt"
  KEY="${CERT_DIR}/dev.key"

  if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
    nginx_log "Generating self-signed certificate for ${DOMAIN} (development only)..."

    mkdir -p "$CERT_DIR"

    if ! command -v openssl >/dev/null 2>&1; then
      apk add --no-cache openssl >/dev/null
    fi

    openssl req \
      -x509 \
      -nodes \
      -newkey rsa:2048 \
      -days 3650 \
      -keyout "$KEY" \
      -out "$CRT" \
      -subj "/CN=${DOMAIN}"
  else
    nginx_log "Reusing existing development self-signed certificate for ${DOMAIN}."
  fi
elif [ "$CURRENT_ENV" = "production" ]; then
  : "${DOMAIN:?"DOMAIN not defined."}"
  nginx_log "Using externally managed certificates for ${DOMAIN} (no self-signed generation)."
else
  nginx_log "Unsupported CURRENT_ENV='${CURRENT_ENV}'. Expected 'development' or 'production'."
  exit 1
fi

nginx_log "Starting nginx..."
nginx

RELOAD_INTERVAL="6h"

while :; do
  sleep "$RELOAD_INTERVAL"
  nginx_log "Reloading nginx..."
  nginx -s reload || true
done
