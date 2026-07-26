# Hack The Box — Nibbles

> A write-up for the **retired** Hack The Box machine *Nibbles*. Retired machines are approved for
> public publication under HTB's content-sharing rules.

> ℹ️ **Defanging & redaction note.** Lab IPs are RFC 1918 / HTB lab space and are defanged only for
> filter compatibility, not for safety. Payloads are neutralized, operator identity is `<operator>`,
> and flag values are `[REDACTED]`. See [`SANITIZATION.md`](../../SANITIZATION.md).

## Status

**In progress.** This case is being documented in solve order; each phase is added as a separate
milestone. Read `git log --reverse` to follow it as a first-time solve.

| Phase                 | Status      |
| --------------------- | ----------- |
| Reconnaissance        | Pending     |
| Enumeration           | Pending     |
| Initial access        | Pending     |
| Privilege escalation  | Pending     |
| Proof                 | Pending     |
| Remediation           | Pending     |

## Machine profile

| Field            | Value            |
| ---------------- | ---------------- |
| Name             | Nibbles          |
| Operating System | Linux            |
| Difficulty       | Easy             |
| Release date     | January 13, 2018 |
| Creator          | mrb3n            |
| Status           | Retired          |

## Directory map

```text
nibbles/
├── README.md                 # this overview (grows per milestone)
├── recon/                    # nmap, service enumeration
├── exploitation/             # initial access, shell notes
├── privilege-escalation/     # privesc path
├── proof/                    # flag capture (values redacted)
├── screenshots/              # metadata-stripped images
├── references/               # advisories, tools, research
└── remediation.md            # defensive takeaways (added at the remediation milestone)
```

## Disclaimer

This write-up documents an authorized penetration-testing exercise conducted exclusively against an
intentionally vulnerable training environment. No techniques are documented against systems outside
explicitly authorized training environments.
