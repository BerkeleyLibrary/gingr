#!/usr/bin/env bash
set -euo pipefail

HEALTH_URL="${GEOSERVER_URL:-http://localhost:8080/geoserver/web/}"
WAIT_ATTEMPTS="${WAIT_ATTEMPTS:-60}"

echo "Waiting for geoserver to be healthy..."
for ((attempt = 1; attempt <= WAIT_ATTEMPTS; attempt++)); do
  if curl -fsS "$HEALTH_URL" >/dev/null 2>&1; then
    echo "GeoServer is healthy (attempt $attempt)"
    break
  fi
  if [[ $attempt -eq $WAIT_ATTEMPTS ]]; then
    echo "ERROR: GeoServer did not become healthy after $WAIT_ATTEMPTS attempts" >&2
    exit 1
  fi
  echo "  attempt $attempt/$WAIT_ATTEMPTS — not ready yet, waiting 10s..."
  sleep 10
done

echo "Copying OIDC seed config files..."
docker compose exec geoserver mkdir -p /opt/geoserver_data/security/filter/keycloak
docker compose exec geoserver cp /opt/seed/security/config.xml /opt/geoserver_data/security/config.xml
docker compose exec geoserver cp /opt/seed/security/filter/keycloak/config.xml /opt/geoserver_data/security/filter/keycloak/config.xml

echo "Restarting geoserver..."
docker compose restart geoserver

echo "Done."