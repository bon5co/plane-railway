#!/bin/bash
# Railway wrapper entrypoint for Plane (all-in-one community image).
#
# Boots Plane with Caddy bound to loopback only, waits for the database
# migrations to finish and the Instance singleton to exist, seeds the instance
# administrator (upstream has no env/CLI path to do this and leaves the
# sign-up endpoint open to any anonymous caller until an admin exists), then
# hot-reloads Caddy onto the public $PORT. The public port therefore never
# serves an unclaimed instance.
set -e

: "${PORT:=8080}"
INTERNAL_PORT="${INTERNAL_PORT:-8090}"
export SITE_ADDRESS="127.0.0.1:${INTERNAL_PORT}"

echo "[railway] starting Plane; proxy bound to 127.0.0.1:${INTERNAL_PORT} until admin is seeded"
/app/start.sh &
BOOT_PID=$!

cd /app/backend

echo "[railway] waiting for migrations + instance registration"
ready=0
for i in $(seq 1 180); do
  if ! kill -0 "$BOOT_PID" 2>/dev/null; then
    echo "[railway] boot process exited before instance was ready"; wait "$BOOT_PID"; exit 1
  fi
  if python manage.py shell -c "import sys; from plane.license.models import Instance; sys.exit(0 if Instance.objects.exists() else 1)" >/dev/null 2>&1; then
    ready=1
    echo "[railway] instance registered (~$((i*10))s)"
    break
  fi
  sleep 10
done

if [ "$ready" != "1" ]; then
  echo "[railway] instance never registered; leaving proxy on loopback and refusing to open the public port"
  wait "$BOOT_PID"; exit 1
fi

echo "[railway] seeding instance admin"
python manage.py shell < /app/seed_admin.py

echo "[railway] opening public port ${PORT}"
# Source plane.env so the Caddyfile's {$FILE_SIZE_LIMIT}, {$TRUSTED_PROXIES}
# etc. resolve exactly as they did for the supervisor-launched proxy; only
# SITE_ADDRESS is overridden, from loopback to the public port.
set -a; . /app/plane.env; set +a
if SITE_ADDRESS=":${PORT}" caddy reload --config /app/proxy/Caddyfile --adapter caddyfile; then
  echo "[railway] proxy now listening on :${PORT}"
else
  echo "[railway] caddy reload failed" >&2
  wait "$BOOT_PID"; exit 1
fi

wait "$BOOT_PID"
