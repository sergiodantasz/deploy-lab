#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log.sh"

ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$ROOT/.env" ]; then
  set -a
  . "$ROOT/.env"
  set +a
fi

if [ "$CURRENT_ENV" = "development" ]; then
  ENV_DIR=dev
elif [ "$CURRENT_ENV" = "production" ]; then
  ENV_DIR=prod
else
  setup_log "CURRENT_ENV must be development or production, got: $CURRENT_ENV" >&2
  exit 1
fi

SRC="$ROOT/nginx/templates/${ENV_DIR}"
DEST="$ROOT/nginx/conf.d/${ENV_DIR}"

if [ ! -d "$SRC" ]; then
  setup_log "No templates for ${CURRENT_ENV}: ${SRC} not found" >&2
  exit 1
fi

mkdir -p "$DEST"

render_template() {
  local f="$1" out="$2"
  while IFS= read -r line; do
    line="${line//\$\{NGINX_UPSTREAM_SERVICE\}/$NGINX_UPSTREAM_SERVICE}"
    line="${line//\$\{DOMAIN\}/$DOMAIN}"
    printf '%s\n' "$line"
  done < "$f" > "$out"
}

if [ "$CURRENT_ENV" = "production" ]; then
  CERTBOT_CONF="$ROOT/certbot/conf"
  CERT_FILE="${CERTBOT_CONF}/live/${DOMAIN}/fullchain.pem"

  if [ -f "$CERT_FILE" ]; then
    PROD_TEMPLATES=( "app.conf" )
    setup_log "Certificate found at ${CERT_FILE}; using app template"
  else
    PROD_TEMPLATES=( "challenge.conf" )
    setup_log "No certificate at ${CERT_FILE}; using challenge template only (run certbot to obtain cert)"
  fi

  rm -f "${DEST}"/*.conf
  for name in "${PROD_TEMPLATES[@]}"; do
    f="${SRC}/${name}.template"
    [ -f "$f" ] || { setup_log "Template not found: $f" >&2; exit 1; }
    render_template "$f" "${DEST}/${name}"
  done

else
  DEV_CERT_DIR="$ROOT/nginx/certs"
  DEV_CRT="${DEV_CERT_DIR}/dev.crt"
  DEV_KEY="${DEV_CERT_DIR}/dev.key"

  if [ -f "$DEV_CRT" ] && [ -f "$DEV_KEY" ]; then
    setup_log "Development certificate already exists (${DEV_CRT}, ${DEV_KEY})"
  else
    setup_log "Development certificate not found. It will be generated on nginx startup."
  fi

  for f in "${SRC}"/*.conf.template; do
    [ -f "$f" ] || continue
    out_name="$(basename "$f" .template)"
    render_template "$f" "${DEST}/${out_name}"
  done
fi

setup_log "Nginx configuration ready!"
setup_log "  - Templates  : ${SRC} → ${DEST}"
setup_log "  - Environment: ${CURRENT_ENV}"
setup_log "  - Upstream   : ${NGINX_UPSTREAM_SERVICE}"
setup_log "  - Domain     : ${DOMAIN}"
