#!/usr/bin/env bash
# Idempotent installer for SvátekTracker's server-side analytics. Run ON the
# update host as root, from the directory holding this script + collect.sh +
# goaccess.conf (e.g. after scp'ing scripts/analytics/ over). Re-running is safe.
#
# Installs GoAccess, lays down /opt/svatektracker-analytics with the collector,
# a 15-min cron entry and monthly logrotate, then builds the first report.
# Touches nothing else on the box — no container, nginx or Traefik changes.
set -euo pipefail
DIR=/opt/svatektracker-analytics
SRC=$(cd "$(dirname "$0")" && pwd)

command -v goaccess >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y goaccess; }

mkdir -p "$DIR"
install -m 0755 "$SRC/collect.sh"   "$DIR/collect.sh"
install -m 0644 "$SRC/goaccess.conf" "$DIR/goaccess.conf"

# Ship logs + rebuild the report every 15 minutes.
cat > /etc/cron.d/svatektracker-analytics <<'CRON'
# SvátekTracker analytics: collect nginx access lines + rebuild GoAccess report.
*/15 * * * * root /opt/svatektracker-analytics/collect.sh >> /opt/svatektracker-analytics/cron.log 2>&1
CRON

# Rotate the persistent access log monthly; copytruncate so the collector can
# keep appending without a reopen.
cat > /etc/logrotate.d/svatektracker-analytics <<'LR'
/opt/svatektracker-analytics/access.log {
  monthly
  rotate 12
  compress
  missingok
  notifempty
  copytruncate
}
LR

# First collection + report build.
"$DIR/collect.sh"
echo "analytics ready — report at $DIR/report.html"
