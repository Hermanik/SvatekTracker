#!/usr/bin/env bash
# (Re)creates the svatektracker-updates nginx container on the update host —
# the static server behind Traefik that serves the appcast/DMGs and the download
# page. Idempotent: safe to re-run; only touches this one container.
#
# Run ON the host as root (the box already runs Coolify's Traefik on the
# `coolify` network), e.g. from the Mac with the .release.env target:
#   source .release.env
#   ssh -i "$UPDATE_SSH_KEY" "$UPDATE_HOST" 'bash -s' < scripts/setup-update-host.sh
#
# Routing (mirrors the other *Tracker apps' update containers, with unique
# `svt*` router/middleware names so they coexist):
#   - updates.jsemkoder.cz/svatektracker/*  → appcast + DMGs (a more specific
#     rule than the catch-all on the same host, so it wins for that path)
#   - svatektracker.jsemkoder.cz/           → download page (addprefix /svatektracker)
#   - http on both → 301 to https (so downloads aren't flagged insecure)
# DNS: svatektracker.jsemkoder.cz must be an A record to this box, DNS-only
# (proxied=false) or Traefik's ACME http-challenge fails with 522.
set -euo pipefail

mkdir -p /opt/svatektracker-updates
docker rm -f svatektracker-updates >/dev/null 2>&1 || true
docker run -d --name svatektracker-updates --restart unless-stopped --network coolify \
  -v /opt/svatektracker-updates:/usr/share/nginx/html/svatektracker:ro \
  --label traefik.enable=true \
  --label 'traefik.http.middlewares.svtprefix.addprefix.prefix=/svatektracker' \
  --label 'traefik.http.middlewares.svtredirect.redirectscheme.scheme=https' \
  --label 'traefik.http.middlewares.svtredirect.redirectscheme.permanent=true' \
  --label 'traefik.http.services.svtu.loadbalancer.server.port=80' \
  --label 'traefik.http.routers.svtu-http.entryPoints=http' \
  --label 'traefik.http.routers.svtu-http.rule=Host(`updates.jsemkoder.cz`) && PathPrefix(`/svatektracker`)' \
  --label 'traefik.http.routers.svtu-http.middlewares=svtredirect' \
  --label 'traefik.http.routers.svtu-http.service=svtu' \
  --label 'traefik.http.routers.svtu-https.entryPoints=https' \
  --label 'traefik.http.routers.svtu-https.rule=Host(`updates.jsemkoder.cz`) && PathPrefix(`/svatektracker`)' \
  --label 'traefik.http.routers.svtu-https.service=svtu' \
  --label 'traefik.http.routers.svtu-https.tls=true' \
  --label 'traefik.http.routers.svtu-https.tls.certresolver=letsencrypt' \
  --label 'traefik.http.routers.svtpage-http.entryPoints=http' \
  --label 'traefik.http.routers.svtpage-http.rule=Host(`svatektracker.jsemkoder.cz`)' \
  --label 'traefik.http.routers.svtpage-http.middlewares=svtredirect' \
  --label 'traefik.http.routers.svtpage-http.service=svtu' \
  --label 'traefik.http.routers.svtpage-https.entryPoints=https' \
  --label 'traefik.http.routers.svtpage-https.rule=Host(`svatektracker.jsemkoder.cz`)' \
  --label 'traefik.http.routers.svtpage-https.middlewares=svtprefix' \
  --label 'traefik.http.routers.svtpage-https.service=svtu' \
  --label 'traefik.http.routers.svtpage-https.tls=true' \
  --label 'traefik.http.routers.svtpage-https.tls.certresolver=letsencrypt' \
  nginx:alpine

docker ps --filter name=svatektracker-updates --format 'created: {{.Names}} | {{.Image}} | {{.Status}}'
