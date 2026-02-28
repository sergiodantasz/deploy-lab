#!/bin/sh

set -eu

: "${DOMAINS:?"DOMAINS not defined."}"
: "${EMAIL:?"EMAIL not defined."}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/log.sh"

PRIMARY_DOMAIN=$(echo "$DOMAINS" | awk '{print $1}')
CERT_DIR="/etc/letsencrypt/live/${PRIMARY_DOMAIN}"
WEBROOT="/var/www/certbot"

if [ ! -d "$CERT_DIR" ]; then
  certbot_log "No certificate found for ${DOMAINS}. Issuing a new one..."
  certbot_args=""
  for d in $DOMAINS; do
    certbot_args="${certbot_args} -d ${d}"
  done
  certbot certonly \
    --webroot \
    -w "$WEBROOT" \
    $certbot_args \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --non-interactive
else
  certbot_log "Certificate already exists for ${PRIMARY_DOMAIN}. Skipping issuance."
fi

while :; do
  certbot_log "Running renewal check..."
  certbot renew --webroot -w "$WEBROOT" --non-interactive
  sleep 12h
done
