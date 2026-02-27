#!/usr/bin/env bash

RESET="\033[0m"
BOLD="\033[1m"

BLUE="\033[34m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
MAGENTA="\033[35m"

log() {
  local context="$1"
  local message="$2"
  local color="$3"

  printf "%b[%s]%b %s\n" "${color}${BOLD}" "$context" "$RESET" "$message"
}

app_log() {
  log "app" "$1" "$YELLOW"
}

nginx_log() {
  log "nginx" "$1" "$CYAN"
}

setup_log() {
  log "setup" "$1" "$BLUE"
}

cleanup_log() {
  log "cleanup" "$1" "$RED"
}

certbot_log() {
  log "certbot" "$1" "$MAGENTA"
}
