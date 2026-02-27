#!/bin/sh

set -eu

: "${DOMAIN:?"DOMAIN not defined."}"
: "${EMAIL:?"EMAIL not defined."}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/log.sh"

CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"
WEBROOT="/var/www/certbot"

if [ ! -d "$CERT_DIR" ]; then
  certbot_log "No certificate found for ${DOMAIN}. Issuing a new one..."
  certbot certonly \
    --webroot \
    -w "$WEBROOT" \
    -d "$DOMAIN" \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --non-interactive
else
  certbot_log "Certificate already exists for ${DOMAIN}. Skipping issuance."
fi

while :; do
  certbot_log "Running renewal check..."
  certbot renew --webroot -w "$WEBROOT" --non-interactive
  sleep 12h
done
