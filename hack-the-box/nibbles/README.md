# Hack The Box — Nibbles

> A write-up for the **retired** Hack The Box machine *Nibbles*. Retired machines are approved for
> public publication under HTB's content-sharing rules.

> ℹ️ **Defanging & redaction note.** Lab IPs are HTB lab space (RFC 1918) and are defanged only for
> filter compatibility, not for safety. Payloads are neutralized, operator identity is `<operator>`,
> and flag values are `[REDACTED]`. See [`SANITIZATION.md`](../../SANITIZATION.md).

## Status: Complete

All phases documented. Read `git log --reverse` to follow the engagement as a first-time solve.

| Phase                | Status   |
|----------------------|----------|
| Reconnaissance       | ✅ Complete |
| Web Footprinting     | ✅ Complete |
| Initial Access       | ✅ Complete |
| Privilege Escalation | ✅ Complete |
| Proof                | ✅ Complete |
| Remediation          | ✅ Complete |

---

## Machine Profile

| Field            | Value             |
|------------------|-------------------|
| Name             | Nibbles           |
| Operating System | Ubuntu 16.04 LTS  |
| Difficulty       | Easy              |
| Release Date     | January 13, 2018  |
| Creator          | mrb3n             |
| HTB Status       | Retired           |

---

## Attack-Path Summary

```text
nmap (ports 22, 80)
        ↓
Apache 2.4.18 on port 80
        ↓
HTML comment discloses /nibbleblog/
        ↓
WhatWeb → Nibbleblog CMS identified
        ↓
Gobuster → admin.php + README discovered
        ↓
README → version 4.0.3 (CVE-2015-6967 version-applicable)
        ↓
Directory listing → users.xml (admin) + config.xml (nibbles)
        ↓
admin:nibbles → authenticated to admin portal
        ↓
My image plugin → PHP webshell upload (GD warnings)
        ↓
image.php → uid=1001(nibbler) — RCE confirmed
        ↓
Reverse shell → interactive TTY as nibbler
        ↓
user.txt [REDACTED]
        ↓
personal.zip → monitor.sh (rwxrwxrwx)
        ↓
sudo -l → (root) NOPASSWD: monitor.sh
        ↓
Payload appended → sudo trigger → root shell
        ↓
root.txt [REDACTED]
```

---

## Key Findings

| Finding | Severity | Phase |
|---------|----------|-------|
| Default/guessable admin credentials (`admin:nibbles`) | Critical | Web footprinting |
| Nibbleblog v4.0.3 — authenticated file upload RCE (CVE-2015-6967) | Critical | Initial access |
| PHP execution in upload directory | Critical | Initial access |
| World-writable script with NOPASSWD sudo (`monitor.sh`) | Critical | Privilege escalation |
| Directory listing enabled (exposes config store) | High | Web footprinting |
| Sensitive config files web-accessible (`users.xml`, `config.xml`) | High | Web footprinting |
| Verbose PHP error messages (discloses server paths) | Medium | Initial access |
| `PermitRootLogin yes` in SSH config | Medium | Privilege escalation |
| Version-identifying README publicly accessible | Medium | Web footprinting |

---

## MITRE ATT&CK Mapping (Defender's View)

| Tactic | Technique | ID | Phase |
|--------|-----------|-----|-------|
| Reconnaissance | Active Scanning: Network Service Discovery | T1046 | Recon |
| Discovery | File and Directory Discovery | T1083 | Web footprinting |
| Credential Access | Unsecured Credentials: Credentials in Files | T1552.001 | Web footprinting |
| Initial Access | Exploit Public-Facing Application | T1190 | Initial access |
| Execution | Command and Scripting Interpreter: Unix Shell | T1059.004 | Initial access |
| Command and Control | Ingress Tool Transfer | T1105 | Privilege escalation |
| Discovery | System Information Discovery | T1082 | Privilege escalation |
| Privilege Escalation | Abuse Elevation Control Mechanism: Sudo and Sudo Caching | T1548.003 | Privilege escalation |

---

## Tools Used

| Tool | Purpose |
|------|---------|
| nmap | Network and service enumeration |
| whatweb | Web application fingerprinting |
| gobuster | Directory enumeration |
| curl | HTTP interaction, authentication, RCE trigger |
| xmllint | XML config file inspection |
| LinEnum | Automated local privilege-escalation enumeration |
| netcat | Reverse-shell listener |
| python3 (pty) | TTY upgrade |

---

## Directory Map

```text
nibbles/
├── README.md                              # this overview
├── recon/
│   ├── nmap.md                            # network recon (ports 22, 80)
│   └── web-enumeration.md                 # web footprinting → version applicability
├── exploitation/
│   └── initial-access.md                  # credentials → RCE → reverse shell → user proof
├── privilege-escalation/
│   └── privilege-escalation.md            # monitor.sh → sudo → root proof
├── proof/
│   └── flags.md                           # user + root flags [REDACTED]
├── screenshots/                           # metadata-stripped images
├── references/
│   ├── sources.md                         # CVE + Rapid7 citations
│   └── file-transfer-techniques.md        # HTTP server, SCP, base64 reference
└── remediation.md                         # kill-chain-aware defensive recommendations
```

---

## Primary Defensive Lesson

> Individually moderate weaknesses — including default credentials, insufficient upload validation,
> executable upload directories, and an unsafe `sudo` policy — combined into a complete compromise.
> Eliminating any one of the critical links in the chain would have prevented root-level access.

See [`remediation.md`](remediation.md) for the full three-tier remediation analysis and detection
opportunities.

---

## Disclaimer

This write-up documents an authorized penetration-testing exercise conducted exclusively against an
intentionally vulnerable training environment. No techniques are documented against systems outside
explicitly authorized training environments.
