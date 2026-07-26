#!/usr/bin/env bash
#
# audit-sensitive-data.sh — custom sensitive-data audit for the penetration-testing portfolio.
#
# Redundant backstop to gitleaks, tuned to THIS repo's leak surface (offensive write-ups):
# operator identity, un-defanged routable IPs/URLs, unredacted flags, and un-neutralized payloads.
# Classifies matches as REVIEW (needs a human decision) vs. allow-listed (known-safe box content),
# so it only surfaces what actually needs a decision.
#
# Content-convention checks (URLs / IPs / payloads / flags) apply to WRITE-UP MARKDOWN only —
# tooling, CI config, and control docs legitimately contain real URLs and detection patterns.
#
# Usage:   bash scripts/audit-sensitive-data.sh [path]        (default path: .)
# Exit:    0 = "AUDIT CLEAN"     1 = "AUDIT: REVIEW REQUIRED"
#
set -uo pipefail
TARGET="${1:-.}"
BASE="${TARGET%/}"

# Target-side (box) users that legitimately appear in output; NOT operator identity.
BOX_USERS='nibbler|root|www-data|admin'

# Write-up content = Markdown, excluding tooling, templates, and root-level control docs.
mapfile -t SCAN < <(
  find "$TARGET" -type f -name '*.md' \
       -not -path '*/.git/*' -not -path '*/scripts/*' -not -path '*/.github/*' \
       -not -path '*/templates/*' 2>/dev/null \
    | grep -vE "/(SECURITY|SANITIZATION|CONTRIBUTING)\.md$" \
    | grep -vE "^${BASE}/README\.md$"
)

review=0
section() { printf '\n=== %s ===\n' "$1"; }
hit()     { review=$((review+1)); printf '  [REVIEW] %s\n' "$1"; }
scan()    { [ "${#SCAN[@]}" -gt 0 ] && grep -InE -e "$1" "${SCAN[@]}" 2>/dev/null; }

# 1) Operator-identity leaks: usernames in attack-VM contexts (sudo prompts) and home paths.
section "Operator identity"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  user=$(sed -E 's/.*password for ([a-z_][a-z0-9_-]*).*/\1/' <<<"$line")
  grep -qE "^($BOX_USERS)\$" <<<"$user" || hit "possible operator username in sudo prompt: $line"
done < <(scan 'password for [a-z_][a-z0-9_-]*')
while IFS= read -r m; do
  u=$(sed -E 's#.*/home/([a-z_][a-z0-9_-]+)/.*#\1#' <<<"$m")
  grep -qE "^($BOX_USERS)\$" <<<"$u" && continue
  grep -q '/home/<operator>' <<<"$m" && continue
  hit "possible operator home path: $m"
done < <(scan '/home/[a-z_][a-z0-9_-]+/')

# 2) Un-defanged URLs (published write-ups must use hxxp/hxxps).
section "Un-defanged URLs"
while IFS= read -r m; do hit "bare URL (should be hxxp/hxxps): $m"; done \
  < <(scan 'https?://' | grep -vE 'hxxps?://')

# 3) Un-defanged / routable IPs. Allow defanged form and RFC1918 + loopback bare forms.
section "Routable / un-defanged IPs"
while IFS= read -r m; do
  ip=$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' <<<"$m" | head -1)
  case "$ip" in
    10.*|192.168.*|127.*|0.0.0.0) continue ;;
    172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) continue ;;
  esac
  hit "bare IP not in lab/private space (defang or confirm): $m"
done < <(scan '([0-9]{1,3}\.){3}[0-9]{1,3}')

# 4) Unredacted flags: 32-hex NOT a checksum-format line, NOT in checksum context, NOT redacted.
section "Candidate unredacted flags (32-hex)"
while IFS= read -r m; do
  grep -qE '[0-9a-f]{32}  +\S' <<<"$m" && continue
  grep -qiE 'md5|sha|checksum|integrity|fingerprint' <<<"$m" && continue
  grep -q 'REDACTED' <<<"$m" && continue
  hit "32-hex string — confirm not a flag: $m"
done < <(scan '\b[0-9a-f]{32}\b')

# 5) Un-neutralized reverse-shell payloads (metacharacters must be bracketed).
section "Un-neutralized payloads"
while IFS= read -r m; do
  grep -qE '\[\|\]|\[;\]|\[>\]' <<<"$m" && continue
  hit "reverse-shell one-liner not neutralized: $m"
done < <(scan 'mkfifo .*/tmp/f|/tmp/f *\| */bin/(ba)?sh|nc [^ ]+ [0-9]+ *> */tmp/f')

# 6) Hard secrets: private keys, tokens, live cookie/session values, cleartext passwords.
section "Secrets / keys / tokens"
while IFS= read -r m; do hit "possible secret: $m"; done < <(
  scan '-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ghp_[0-9A-Za-z]{36}|xox[baprs]-[0-9A-Za-z-]+|PHPSESSID=[0-9a-f]{16,}|password\s*[:=]\s*[^ <*][^ ]+' \
    | grep -viE 'password for|no known default|no passwords|nibbles|<|\*\*\*' )

# 7) Working-artifact files that should have been git-ignored (scans whole target).
section "Working artifacts that should be ignored"
while IFS= read -r m; do hit "tracked working artifact: $m"; done < <(
  find "$TARGET" -type f \( -name '*.ovpn' -o -name '*.gnmap' -o -name '*.nessus' \
       -o -name '.env' -o -name '*.conf.local' \) -not -path '*/.git/*' 2>/dev/null)

# ---- verdict ----
printf '\n----------------------------------------\n'
if [ "$review" -eq 0 ]; then echo "AUDIT CLEAN"; exit 0; fi
echo "AUDIT: REVIEW REQUIRED ($review item(s))"; exit 1
