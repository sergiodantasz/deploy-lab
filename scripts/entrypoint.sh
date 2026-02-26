#!/bin/sh

set -e

python src/manage.py migrate

exec gunicorn --chdir src core.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers 1 \
  --timeout 60 \
  --graceful-timeout 45 \
  --keep-alive 10 \
  --access-logfile - \
  --error-logfile - \
  --log-level info
