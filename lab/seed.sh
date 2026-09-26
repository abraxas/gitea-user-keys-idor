#!/usr/bin/env bash
# Create victim + attacker and plant a witness SSH key on the victim.
set -euo pipefail
CID="${1:?container}"
WORKDIR="${2:-/tmp/gitea-key-idor}"
mkdir -p "$WORKDIR"
if [[ ! -f "$WORKDIR/victim.pub" ]]; then
  ssh-keygen -t ed25519 -N "" -C "GHSA-GITEA-KEY-IDOR-WITNESS" -f "$WORKDIR/victim" >/dev/null
fi
if [[ ! -f "$WORKDIR/attacker.pub" ]]; then
  ssh-keygen -t ed25519 -N "" -C "attacker-own-key" -f "$WORKDIR/attacker" >/dev/null
fi

create_user() {
  local name="$1"
  docker exec -u git "$CID" gitea admin user create \
    --username "$name" \
    --password LabPass123! \
    --email "${name}@localhost.invalid" \
    --must-change-password=false \
    >/dev/null 2>&1 || true
}

create_user victim
create_user attacker

python3 - <<PY
import json, ssl, urllib.request, urllib.error, base64
BASE="http://127.0.0.1:18101"
CTX=ssl._create_unverified_context()
WITNESS="GHSA-GITEA-KEY-IDOR-WITNESS"

def req(method, path, data=None, user=None):
    hdrs={"Content-Type":"application/json","User-Agent":"gitea-key-idor-lab"}
    if user:
        tok=base64.b64encode(f"{user}:LabPass123!".encode()).decode()
        hdrs["Authorization"]="Basic "+tok
    body=None if data is None else json.dumps(data).encode()
    r=urllib.request.Request(BASE+path, data=body, headers=hdrs, method=method)
    try:
        with urllib.request.urlopen(r, timeout=30, context=CTX) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()

def add_key(user, title, pub):
    s,b=req("GET","/api/v1/user/keys", user=user)
    if s==200 and title in b:
        print(f"IOC key-exists user={user}")
        return
    s,b=req("POST","/api/v1/user/keys", {"title": title, "key": pub.strip()}, user=user)
    print(f"IOC add-key user={user} status={s} snippet={b[:160]!r}")
    if s not in (200,201):
        raise SystemExit(f"FAIL add key {user}")

victim_pub=open("$WORKDIR/victim.pub").read()
attacker_pub=open("$WORKDIR/attacker.pub").read()
add_key("victim", WITNESS, victim_pub)
add_key("attacker", "attacker-own-key", attacker_pub)
print("IOC seed-done")
PY
