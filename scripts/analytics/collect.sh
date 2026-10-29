#!/usr/bin/env bash
# Ships new nginx access lines out of the rotating Docker json-log (capped at
# 30 MB, so older history would otherwise be lost) into a persistent log, then
# rebuilds the GoAccess HTML dashboard over the full history. Runs from cron
# every 15 min; safe to run by hand. Lives at /opt/svatektracker-analytics/.
set -euo pipefail
DIR=/opt/svatektracker-analytics
LOG="$DIR/access.log"
STAMP="$DIR/.last"
CONTAINER=svatektracker-updates

# Append only lines newer than the previous run; the first run grabs whatever
# is still buffered. Drop nginx error lines — keep real access entries (they
# start with an IP). Any boundary-second overlap is negligible for trend counts.
prev=$(cat "$STAMP" 2>/dev/null || true)
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
if [ -n "$prev" ]; then
  docker logs --since "$prev" "$CONTAINER" 2>&1
else
  docker logs "$CONTAINER" 2>&1
fi | grep -E '^[0-9.]+ - - \[' >> "$LOG" || true
printf '%s\n' "$now" > "$STAMP"

# Rebuild the dashboard over current + rotated (.gz) logs. zcat -f also reads
# the plain current file. Empty input on a fresh box is fine.
if [ -s "$LOG" ] || ls "$LOG".* >/dev/null 2>&1; then
  zcat -f "$LOG"* 2>/dev/null \
    | goaccess - -o "$DIR/report.html" \
        --no-global-config --config-file="$DIR/goaccess.conf"
fi
