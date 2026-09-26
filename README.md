<p align="center">
  <img src="header.png" alt="Abraxas Labs — gitea-user-keys-idor" width="100%">
</p>

<p align="center">
  <a href="https://abraxaslabs.tech"><strong>abraxaslabs.tech</strong></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/abraxas">github.com/abraxas</a>
  &nbsp;·&nbsp;
  <a href="https://x.com/abraxas_null">@abraxas_null</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/abraxas/gitea-user-keys-idor">gitea-user-keys-idor</a>
</p>

# gitea-user-keys-idor

**Gitea** `1.27.3` — Gitea

Unpublished Gitea source finding: SSH/deploy-key IDOR on GET /api/v1/user/keys/{id}.

| | |
|---|---|
| ID | Unpublished Gitea source finding #1 (no CVE yet) |
| CWE | [CWE-639](https://cwe.mitre.org/data/definitions/639.html) |
| CVSS | **High: 7.5** `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N` |
| Product | [Gitea](https://github.com/go-gitea/gitea) |
| Affected | all versions **through 1.27.3** (inclusive) |
| Patched | vendor patch — see references |
| Auth | authenticated (see source map) |
| License | [GNU Affero GPL v3.0](LICENSE) |
| Lab | `127.0.0.1` only · vendor/client disclosure pack, not a scanner |

---

## Advisory (from the source map)

routers/api/v1/user/key.go GetPublicKey. Contrast gpg_keys GetGPGKeyForUserByID(ctx, ctx.Doer.ID, id). Unpublished vs 1.27.3 username-scoped list GHSA.

---

## Entry

- **Method:** `GET`
- **Path:** `/api/v1/user/keys/{id}`
- **Router:** Authenticated GET. GetPublicKey loads public_key by numeric ID with no OwnerID check. List endpoint stays owner-scoped.
- **Notes:** Authenticated unpublished Gitea #1 CWE-639 v1.27.3. Witness: GHSA-GITEA-KEY-IDOR-WITNESS in foreign key JSON. Not eval. Not a reverse shell.

### Call chain

- `Basic auth as attacker (read:user)`
- `GET /api/v1/user/keys (own list, no witness)`
- `GET /api/v1/user/keys/{id} walk 1..N`
- `GetPublicKey -&gt; GetPublicKeyByID no owner check -&gt; ToPublicKey`

### Lab preconditions

- Gitea 1.27.3 (and likely earlier)
- Any account with read:user (default registration)
- At least one other user's SSH or deploy key

### Witness

GET /api/v1/user/keys/{id} as attacker returns GHSA-GITEA-KEY-IDOR-WITNESS; attacker list does not

### Not success

- eval/base64/system payload
- reverse shell
- own key id

---

## Patch / remediation

**Do this first:** Apply the vendor patch for **Gitea**. See references.

**Verify after upgrade**

- Re-run `gitea-user-keys-idor-Abraxas-Labs.py` against the patched build: the mapped witness must **not** appear.
- Confirm the vendor advisory / changeset in the deployed tree (see references).
- A WAF signature is delay, not a patch.

**If you cannot update immediately**

- Disable or isolate the affected component.
- Hunt for the witness condition on production (new privileged users, unexpected files, injected rows — whatever this CVE's map names).

---

## Reproduction (authorized lab)

Target **only** `http://127.0.0.1:8088` (or the loopback you bound). Do not point this script at the internet.

```bash
python3 gitea-user-keys-idor-Abraxas-Labs.py
```

Success is the **witness** above in the response body. Generic 200 HTML is not it.

---

## Lab images

Loopback stack used to reproduce. Official images unless a `Dockerfile` in this folder builds from source.

- [`lab/docker-compose.yml`](lab/docker-compose.yml)
- [`lab/Dockerfile`](lab/Dockerfile)
- [`lab/run.sh`](lab/run.sh)
- [`lab/seed.sh`](lab/seed.sh)

```bash
cd lab
docker compose up --force-recreate
```

Bind the vulnerable product tree next to Compose if the YAML mounts a local directory (plugin zip / source tag from the version table). Publish nothing except `127.0.0.1`.

---

## References

- [github.com/go-gitea/gitea](https://github.com/go-gitea/gitea) tag v1.27.3

- Abraxas Labs: [abraxaslabs.tech](https://abraxaslabs.tech) · [github.com/abraxas](https://github.com/abraxas) · [@abraxas_null](https://x.com/abraxas_null)

---

## Records (structured)

```
# Gitea unpublished #1 — user/keys IDOR

CWE: CWE-639
Severity: High (source review)

## Description

`GET /api/v1/user/keys/{id}` loads `public_key` by numeric ID with no owner check. An authenticated user can inventory other users' SSH public keys and deploy keys.

## Product

Gitea 1.27.3. Lab oracle is a witness key title, not a shell.
```

---

## License

This disclosure pack is licensed under the **GNU Affero General Public License v3.0**. See [LICENSE](LICENSE).

---

## Disclaimer

This pack is for **the vendor, the site owner, and licensed labs**. The script talks to `127.0.0.1`. Using it against systems you do not own is not authorized by Abraxas Labs. No warranty.

<p align="center">
  <a href="https://abraxaslabs.tech">abraxaslabs.tech</a> ·
  <a href="https://github.com/abraxas">github.com/abraxas</a> ·
  <a href="https://x.com/abraxas_null">@abraxas_null</a>
</p>
