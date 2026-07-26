# Sanitization & Publication Gate

This repository publishes only sanitized material from **retired / intentionally vulnerable**
training environments. Sanitization is **layered and redundant**: content is authored clean, then
passed through multiple independent gates, and nothing reaches the remote until every gate is green.
A miss at one layer is designed to be caught at the next.

The governing principle is **redact at the source, never rely on the gate alone.** Write clean from
the start using the placeholder scheme below; the automated gates are backstops, not the primary
control.

---

## 1. Placeholder scheme

| Real value (never committed)                     | Published placeholder            |
| ------------------------------------------------ | -------------------------------- |
| Operator's local (attack-VM) username            | `<operator>`                     |
| Operator's home path                             | `/home/<operator>/...`           |
| Attacker / VPN (tun0) address                    | `<ATTACKER_IP>`                  |
| Listener / callback port                         | `<PORT>`                         |
| User flag value                                  | `[REDACTED]`                     |
| Root flag value                                  | `[REDACTED]`                     |
| Any API token, cookie value, session id, password hash unrelated to the intended path | removed entirely |

The **method** used to obtain each flag is documented; the **value** is never published.

## 2. Defanging convention

Lab addresses are RFC 1918 / HTB lab space and are **not sensitive IOCs**. They are defanged only
for Confluence / GitHub acceptable-use filter compatibility, not for safety:

- IPs: `10.129.42.190` → `10[.]129[.]42[.]190`
- URLs: `http://` → `hxxp://`, `https://` → `hxxps://`, dots bracketed
- Executable payload metacharacters: `;` → `[;]`, `|` → `[|]`, `>` → `[>]`

A payload one-liner is considered **neutralized** when its callback host/port are placeholders
**and** its shell metacharacters are bracketed, so the technique is fully legible but cannot be
copy-pasted and run verbatim. Every write-up carries a defanging note; re-fang only inside an
authorized lab.

## 3. Intended-solution vs. operator credentials

- **Intended lab credentials** that are part of a box's documented solution (e.g. the Nibbleblog
  `admin:nibbles` login) **may** be published — they are the teaching content, are already public in
  the platform's own guidance, and cannot be re-fanged into anything sensitive.
- **Operator / private credentials** (your Kali password, SSH keys, VPN certs, real tokens) are
  **never** retained, in any form, redacted or otherwise.

## 4. Box-artifact allowlist (not leaks)

Some strings look sensitive but are box content and are kept:

- Box-internal e-mail addresses and domains (`admin@nibbles.com`, `nibbleblog.com`)
- Target SSH host-key fingerprints (public, in every write-up)
- `md5sum` / `file`-integrity checksums shown to demonstrate a transfer verified correctly
- Illustrative, truncated blobs marked `<SNIP>`

## 5. Screenshots — redact at capture, not after

Cropping after the fact is where leaks slip through, so the primary control is source-side:

- Set a neutral shell prompt before capturing terminal output:
  ```bash
  export PS1='$ '
  ```
- Drive the web portion from a clean / private browser profile — no bookmarks, tabs, account names,
  extensions, or desktop notifications in frame.
- Metadata stripping (EXIF) and a manual visual review remain **mandatory backstops**, not the
  primary redaction method.

## 6. The gate stack (order of enforcement)

1. **Authoring gate** — clean placeholders used from the outset.
2. **Diff gate** — source evidence, defanged notes, and the staged deliverable are cross-checked
   before staging (catches, e.g., an operator username left in a `sudo` prompt).
3. **Transfer gate** — packaged archives carry a SHA-256 checksum, verified on both sides of the
   hop.
4. **Local enforcement** — `scripts/audit-sensitive-data.sh` + `gitleaks` + `pre-commit` hooks
   (`.pre-commit-config.yaml`) block a dirty commit locally.
5. **Remote enforcement** — CI (`.github/workflows/security-gates.yml`) re-runs the authoritative
   scan against the pushed commit. Local hooks can be bypassed (`--no-verify`); CI cannot, so it is
   the true enforcement point. On success it prints the marker **`SECURITY GATES PASSED`**.

## 7. Scope

- Only content officially marked **RETIRED** (or otherwise cleared for publication) by its platform.
- Only authorized, intentionally vulnerable training targets. Nothing against production, client, or
  non-consented systems.
