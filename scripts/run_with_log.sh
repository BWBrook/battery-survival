#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: scripts/run_with_log.sh <log-prefix> <command> [args...]" >&2
  exit 2
fi

prefix="$1"
shift

mkdir -p logs
timestamp="$(date +%F-%H%M%S)"
log_path="logs/${prefix}-${timestamp}.log"

printf 'Logging to %s\n' "$log_path"
"$@" 2>&1 | tee "$log_path"
