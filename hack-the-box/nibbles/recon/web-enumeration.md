# Nibbles — Reconnaissance · Web Footprinting

> A write-up for the **retired** Hack The Box machine *Nibbles*. Retired machines are approved for
> public publication under HTB's content-sharing rules. Continues from
> [`recon/nmap.md`](nmap.md), which established the attack surface (SSH 22, HTTP 80).

> ℹ️ **Defanging note.** Lab IPs are HTB lab space (RFC 1918) and are defanged
> (`10.129.129.43` → `10[.]129[.]129[.]43`, `http://` → `hxxp://`) only for filter compatibility,
> not for safety. Commands reflect the live engagement exactly; only environmental identifiers are
> normalized. Third-party content (a vendor page, an author's contact details, a project's full
> README) is cited or excerpted, never reproduced. **Re-fang only in an authorized lab.** See
> [`SANITIZATION.md`](../../../SANITIZATION.md).

> ℹ️ **Session note.** This phase was performed against a re-provisioned instance at
> `10[.]129[.]129[.]43`; the earlier network scan documented a prior spawn. Target-side facts (ports,
> versions, host keys) are unchanged — the box boots from a fixed image — so each file is faithful to
> its own session.

---

## Step 1 — Fingerprint the web root (whatweb)

With only a bare HTTP service identified during network recon, the first web step is to fingerprint
whatever the server returns at the root.

```bash
whatweb 10[.]129[.]129[.]43
```

```
hxxp://10[.]129[.]129[.]43 [200 OK] Apache[2.4.18], Country[RESERVED][ZZ], HTTPServer[Ubuntu Linux][Apache/2.4.18 (Ubuntu)], IP[10[.]129[.]129[.]43]
```

**Finding:** whatweb fingerprinted the **web server** — Apache 2.4.18 on Ubuntu — but identified **no
CMS, framework, JavaScript library, or generator metadata**. Automated fingerprinting is only as
effective as the information a page exposes, and the landing page (93 bytes, confirmed earlier) offers
almost none. The `Country[RESERVED][ZZ]` value is expected for any RFC 1918 address — private ranges
are intentionally non-geolocatable and resolve to the reserved `ZZ` code, so this does not vary
between instances. With the Apache banner now reported by multiple tools consistently (nmap `-sV`, the
HTTP `Server` header, and whatweb all reading the same authoritative source), the server fingerprint
is well corroborated; the *application* remains unidentified.

**Transition:** automated fingerprinting has stalled at the web-server layer. The next question —
*what application is actually hosted here?* — calls for manual inspection of the page itself.

---

## Step 2 — Inspect the page source (curl)

The rendered page shows only "Hello world!"; the source may carry more.

```bash
curl hxxp://10[.]129[.]129[.]43
```
```html
<b>Hello world!</b>
<!-- /nibbleblog/ directory. Nothing interesting here! -->
```

**Finding:** the HTML source discloses a hidden directory — **`/nibbleblog/`** — via a developer
comment invisible in the rendered page. This is the first actionable lead of the engagement: it
narrows the search space from blind directory brute-forcing to a specific, named path.

**Defender's perspective:** this is classic information disclosure through an HTML comment. The
comment holds no credentials, but it reveals an otherwise-undiscoverable application path. In
production, stray comments can leak administrative directories, internal hostnames, API endpoints, or
technology details; stripping them from production output forces an attacker to spend far more effort
during reconnaissance.

**Transition:** with a concrete path in hand, the investigation pivots from `/` to `/nibbleblog/`.

---

## Step 3 — Fingerprint the discovered path (whatweb)

Point whatweb at the path the comment disclosed.

```bash
whatweb hxxp://10[.]129[.]129[.]43/nibbleblog
```
```
hxxp://10[.]129[.]129[.]43/nibbleblog [301 Moved Permanently] Apache[2.4.18], Country[RESERVED][ZZ], HTTPServer[Ubuntu Linux][Apache/2.4.18 (Ubuntu)], IP[10[.]129[.]129[.]43], RedirectLocation[hxxp://10[.]129[.]129[.]43/nibbleblog/], Title[301 Moved Permanently]
hxxp://10[.]129[.]129[.]43/nibbleblog/ [200 OK] Apache[2.4.18], Cookies[PHPSESSID], Country[RESERVED][ZZ], HTML5, HTTPServer[Ubuntu Linux][Apache/2.4.18 (Ubuntu)], IP[10[.]129[.]129[.]43], JQuery, MetaGenerator[Nibbleblog], PoweredBy[Nibbleblog], Script, Title[Nibbles - Yum yum]
```

**Finding:** where the root was blank, the discovered path fingerprints cleanly. Apache issues a
`301` to the canonical trailing-slash URL, then the application identifies itself: the
`MetaGenerator` and `PoweredBy` tags both name **Nibbleblog**, the `PHPSESSID` cookie confirms PHP is
executing server-side, and HTML5/jQuery round out the stack. The application is now named — a
versionable target rather than a blank page.

**Defender's perspective:** publicly exposed generator metadata and technology identifiers let an
attacker name the application without further probing. These tags are not vulnerabilities in
themselves, but minimizing unnecessary technology disclosure modestly increases the effort required
for targeted enumeration.

**Transition:** a named application is the point at which external vulnerability research becomes
appropriate.

---

## Step 4 — Candidate-vulnerability research

With the application identified as Nibbleblog, public vulnerability references were consulted to
understand its historical attack surface. No assumptions were made about the target's version or
exploitability at this stage; the objective was only to identify candidate vulnerabilities for later
validation. Research provenance is recorded in [`references/sources.md`](../references/sources.md);
third-party pages are cited there, not reproduced here.

| Observation | Detail |
|---|---|
| Vulnerability class | Authenticated arbitrary PHP file upload → remote code execution |
| Identifier | CVE-2015-6967 |
| Affected version | Nibbleblog 4.0.3 |
| Prerequisite | Valid administrative credentials (authenticated exploit) |
| Status | Candidate — pending version verification and prerequisite validation |

> **Following application identification, public vulnerability research identified CVE-2015-6967 as a
> candidate vulnerability affecting Nibbleblog 4.0.3. At this stage, neither the target version nor
> exploitability had been confirmed. Further enumeration was required before selecting or attempting
> any exploitation technique.**

The word that governs the rest of the phase is **authenticated**: any use of this candidate
vulnerability presupposes valid admin credentials, which enumeration has not yet produced.

**Transition:** two open questions remain before this candidate can even be called applicable — the
target's actual version, and the administrative interface the exploit requires. Directory enumeration
addresses both.

---

## Step 5 — Directory enumeration (gobuster)

Map the application's exposed structure.

```bash
gobuster dir -u hxxp://10[.]129[.]129[.]43/nibbleblog/ --wordlist /usr/share/seclists/Discovery/Web-Content/common.txt
```
```
/.htaccess            (Status: 403) [Size: 308]
/.hta                 (Status: 403) [Size: 303]
/.htpasswd            (Status: 403) [Size: 308]
/README               (Status: 200) [Size: 4628]
/admin                (Status: 301) [Size: 325] [--> hxxp://10[.]129[.]129[.]43/nibbleblog/admin/]
/admin.php            (Status: 200) [Size: 1401]
/content              (Status: 301) [Size: 327] [--> hxxp://10[.]129[.]129[.]43/nibbleblog/content/]
/index.php            (Status: 200) [Size: 2987]
/languages            (Status: 301) [Size: 329] [--> hxxp://10[.]129[.]129[.]43/nibbleblog/languages/]
/plugins              (Status: 301) [Size: 327] [--> hxxp://10[.]129[.]129[.]43/nibbleblog/plugins/]
/themes               (Status: 301) [Size: 326] [--> hxxp://10[.]129[.]129[.]43/nibbleblog/themes/]
```

This step maps attack surface rather than identifying technology, and the results fall into three
categories.

**Administrative surface — `admin.php` (200), `admin/` (301).** This is the most important result: the
candidate vulnerability is *authenticated*, which implies a login interface, and enumeration has now
located one. The correct conclusion is precise — the required administrative interface has been
identified, not that the vulnerability is confirmed.

**Version verification — `README` (200).** A publicly readable README offers a way to answer the
still-open version question, turning "Nibbleblog, unknown version" into a checkable claim.

**Application structure — `content/`, `plugins/`, `themes/`, `languages/` (301).** The expected
Nibbleblog layout. At this stage these are architectural observations, not attack vectors, though
`content/` and `plugins/` may matter later given the candidate upload vulnerability.

**Protected dotfiles — `.hta`, `.htaccess`, `.htpasswd` (403).** These returned `403 Forbidden`:
access is denied, but the response confirms the files exist — standard Apache handling of dotfiles,
not evidence of custom hardening by the application owner. The `.htpasswd` presence indicates HTTP
Basic Auth credentials may exist on the server; without a file-disclosure primitive or local access,
however, its contents remain inaccessible, making this an observational finding rather than an
exploitable condition.

**Defender's perspective:** administrative interfaces and version-identifying documentation are
high-value reconnaissance targets. Where operationally appropriate, restricting public access to
documentation and admin entry points — combined with strong authentication and monitoring — reduces
information disclosure and improves detection opportunities.

**Transition:** the README is the single result that can move the candidate vulnerability from
*identified* to *version-applicable*. Read it.

---

## Step 6 — Verify the version (README)

Retrieve the README discovered above. Only the version block is reproduced; the remainder is
third-party project content (author contact details, an example post, install instructions) with no
bearing on the assessment and is omitted.

```bash
curl hxxp://10[.]129[.]129[.]43/nibbleblog/README
```
```
====== Nibbleblog ======
Version: v4.0.3
Codename: Coffee
Release date: 2014-04-01
```

The README additionally states a minimum requirement of PHP 5.2 and notes that the `content`
directory must be writable by Apache/PHP. The latter is an architectural detail of the CMS — not a
vulnerability in itself — but it is relevant context: an authenticated file-upload vulnerability must
write somewhere, and whether that requirement intersects the candidate upload path is a question for
the exploitation phase, not a conclusion to draw here.

**Version-applicability chain:**

```text
Observed README  →  reports "Version: v4.0.3"  (a version *claim*, not cryptographic proof)
        ↓
Public research  →  CVE-2015-6967 affects Nibbleblog 4.0.3
        ↓
Interpretation   →  target-reported version matches the documented affected version
        ↓
Conclusion       →  version applicability established; exploitability remains unproven
```

**Finding:**

> **The publicly accessible README reports Nibbleblog version 4.0.3, which matches the affected
> version documented in public vulnerability references. This establishes version applicability for
> the candidate vulnerability while remaining subject to validation of exploit prerequisites and
> successful exploitation.**

The README is what the application *reports itself to be*; on a static lab image that is a strong
signal, but it does not prove that no files were patched or backported. Version applicability is a
well-supported conclusion, not a proof of exploitability.

**Defender's perspective:** publicly accessible deployment artifacts — installation guides, version
documentation — materially reduce an attacker's uncertainty by disclosing software versions and
release details. Where feasible, such artifacts should be removed or restricted in production to
minimize information disclosure.

---

## Web footprinting summary

| Item | Result |
|---|---|
| **Web root** | Apache 2.4.18 (Ubuntu); no application fingerprint |
| **Disclosed path** | `/nibbleblog/` (via HTML source comment) |
| **Application** | Nibbleblog (PHP; `PHPSESSID`, jQuery, HTML5) |
| **Candidate vulnerability** | CVE-2015-6967 — authenticated file-upload RCE (Nibbleblog 4.0.3) |
| **Administrative interface** | `admin.php` (identified; authentication not yet attempted) |
| **Reported version** | v4.0.3 ("Coffee") — matches the candidate's affected version |
| **Status** | Version applicability established; **exploitability unproven** |

**Takeaway:** manual inspection turned a blank two-port host into a named, version-applicable target.
The engagement has reached its enumeration boundary: the application is identified, its structure
mapped, an administrative interface located, and a candidate vulnerability established as
version-applicable — but not proven exploitable, and its authentication prerequisite is not yet
satisfied. Validating those prerequisites, beginning with administrative access, belongs to the
exploitation phase.

---

**Defensive analysis:** detection opportunities from this phase — directory enumeration
artifacts, information disclosure findings, and credential-discovery indicators — are
documented in [`remediation.md`](../remediation.md) §3.1 and §3.2.
