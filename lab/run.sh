#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export COMPOSE_PROJECT_NAME=gitea-user-keys-idor
chmod +x poc.py seed.sh

echo "== docker compose up (gitea/gitea:1.27.3, loopback) =="
docker compose up -d

echo "== wait for Gitea =="
ok=0
for i in $(seq 1 60); do
  code="$(curl -s -o /tmp/gibody -w '%{http_code}' --max-time 5 http://127.0.0.1:18101/api/v1/version || true)"
  if [[ "$code" == "200" ]]; then
    echo "IOC gitea-up http=$code"
    ok=1
    break
  fi
  echo "IOC wait i=$i http=$code"
  sleep 3
done
if [[ "$ok" != 1 ]]; then
  echo "FAIL Gitea did not become ready"
  docker compose logs --tail=80 gitea
  exit 1
fi

cid="$(docker compose ps -q gitea)"
echo "== seed users + SSH keys =="
./seed.sh "$cid" ./keys

echo "== poc.py =="
python3 poc.py http://127.0.0.1:18101
