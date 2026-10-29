#!/usr/bin/env bash
# Opens the private SvátekTracker analytics dashboard. Fetches the GoAccess
# report (cron rebuilds it on the host every 15 min) over SSH — it is never
# served publicly — opens it locally, then prints a quick summary computed ON
# THE SERVER, so only the few summary lines cross the wire, not the whole log.
#
# Read-only: the cron job is the sole writer, so viewing never races the
# collector. Reads UPDATE_HOST / UPDATE_SSH_KEY like release-dmg.sh (env or the
# gitignored .release.env).
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .release.env ] && source .release.env
: "${UPDATE_HOST:?set UPDATE_HOST (env or .release.env)}" "${UPDATE_SSH_KEY:?set UPDATE_SSH_KEY}"
SSH=(ssh -i "$UPDATE_SSH_KEY" -o BatchMode=yes "$UPDATE_HOST")
OUT="${TMPDIR:-/tmp}/svatektracker-stats.html"

# Fetch the freshly-built dashboard.
"${SSH[@]}" 'cat /opt/svatektracker-analytics/report.html' > "$OUT"

# Headline numbers, computed server-side over current + rotated logs. Downloads
# = full 200 GETs on a .dmg; active installs ≈ unique real IPs (the trailing
# XFF field) hitting appcast.xml.
echo "SvátekTracker — totals to date"
"${SSH[@]}" 'bash -s' <<'EOF'
zcat -f /opt/svatektracker-analytics/access.log* 2>/dev/null | awk '
  /\.dmg/        && /HTTP\/[0-9.]+" 200 / { dmg++ }
  /latest\.dmg/  && /HTTP\/[0-9.]+" 200 / { latest++ }
  /appcast\.xml/ { appc++; ip=$NF; gsub(/"/,"",ip); if (ip != "-" && ip != "") seen[ip]=1 }
  END {
    n=0; for (i in seen) n++;
    printf "  DMG downloads:           %d\n", dmg+0;
    printf "  from website (latest):   %d\n", latest+0;
    printf "  Update checks:           %d\n", appc+0;
    printf "  Unique IPs (~installs):  %d\n", n;
  }'
EOF

echo "  dashboard → $OUT"
if command -v open >/dev/null 2>&1; then open "$OUT"; fi
