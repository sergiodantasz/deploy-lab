#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log.sh"

app_log "Running database migrations..."
python src/manage.py migrate
app_log "Migrations completed."

app_log "Starting Gunicorn..."
exec gunicorn --chdir src core.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers 1 \
  --timeout 60 \
  --graceful-timeout 45 \
  --keep-alive 10 \
  --access-logfile - \
  --error-logfile - \
  --log-level info
