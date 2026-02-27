#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log.sh"

LOCK_FILE="/migrate-state/migrate.lock"
DONE_FILE="/migrate-state/migrate-done"

run_migrations() {
  app_log "Acquired migration lock. Running database migrations..."
  python src/manage.py migrate
  app_log "Migrations completed. Marking as done."
  touch "$DONE_FILE"
}

exec 9>"$LOCK_FILE"

if flock -n 9; then
  run_migrations
else
  app_log "Another container is running migrations. Waiting for completion..."
  while true; do
    if [ -f "$DONE_FILE" ]; then
      app_log "Migrations already applied by another container."
      break
    fi

    if flock -n 9; then
      app_log "Migration lock became available without completion marker. Taking over migrations..."
      run_migrations
      break
    fi

    sleep 2
  done
fi

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
