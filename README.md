# Penetration Testing Portfolio

*Authorized offensive-security exercises, documented from a blue-team-first perspective.*

> **Positioning.** This repository complements my defensive security portfolio. While my primary
> focus is DFIR, SIEM investigation, threat detection, and incident response, understanding
> offensive tradecraft firsthand strengthens my ability to detect, investigate, and remediate
> real-world attacks. Every exercise here is approached with the objective of becoming a more
> effective defender — not as a transition away from blue-team security.

---

## Why this repository exists

Defending well means thinking like the adversary you are defending against. The goal of this
repository is not to become a penetration tester — it is to become a more effective SOC analyst and
incident responder by understanding attacks from the inside. Reconstructing a kill chain from
telemetry, or anticipating where an intruder pivots next in the MITRE ATT&CK matrix, is meaningfully
sharper when you have walked that path yourself. Executing an intrusion end-to-end — enumeration,
foothold, privilege escalation — turns abstract technique into first-hand pattern recognition:

- **Detection engineering** improves when you have generated the exact artifacts an attack leaves
  behind (scan signatures, web-log noise, upload primitives, `sudo` abuse).
- **Kill-chain reconstruction** is faster when you recognize a stage because you have performed it.
- **ATT&CK-based hunting** becomes more informed and forward-looking — you can better anticipate
  which technique may follow because you have made those same decisions under lab conditions.

This repository contains selected offensive-security exercises undertaken for the defensive insight
they produce rather than as a primary discipline. Each write-up therefore ends where a pure
offensive write-up would not: with the **defensive takeaway** — the detection opportunity and the
control that breaks the chain.

## Scope and intent

- A focused set of authorized offensive exercises performed in controlled lab environments.
- Every offensive phase is paired with its defensive lesson (detection, telemetry, remediation).
- Not presented as unrestricted "hacking," and not a claim of penetration testing as a primary role.

## Authorization and publication policy

- Only content that is **officially marked RETIRED** by its platform is published here.
- The first case, **Hack The Box – Nibbles**, is a retired machine; publication of retired-machine
  write-ups is permitted under Hack The Box's content policy.
- All work is performed against explicitly authorized training targets in lab environments. No
  techniques are documented against systems outside authorized training use.
- All published material is sanitized before commit (see **Sanitization & safety**).

## Repository structure

```text
penetration-testing-portfolio/
├── README.md                    # this file — repository identity and policy
├── LICENSE
├── SECURITY.md                  # responsible-use and reporting posture
├── SANITIZATION.md              # placeholder scheme + pre-publication gate
├── CONTRIBUTING.md
├── .gitignore
├── .gitleaks.toml               # secrets backstop (tuned)
├── .pre-commit-config.yaml      # local enforcement gate
├── .github/
│   └── workflows/
│       └── security-gates.yml   # authoritative server-side re-scan
├── scripts/
│   ├── audit-sensitive-data.sh
│   ├── validate-writeups.py
│   └── inspect-images.sh
├── templates/
│   └── TEMPLATE_Penetration_Testing_Writeup.md
└── hack-the-box/
    └── nibbles/                 # see box-level README for the case study
```

## Contents

| Platform      | Target  | OS    | Difficulty | Status      |
| ------------- | ------- | ----- | ---------- | ----------- |
| Hack The Box  | Nibbles | Linux | Easy       | In progress |

*Additional platforms (e.g. offensive labs, vulnerable web applications, Active Directory
exercises) may be added over time under the same retired-/authorized-only policy.*

## Methodology

Each case follows a consistent sequence, and each phase is documented with a defender's lens:

| Phase                 | Offensive objective                          | Defensive lens                                   |
| --------------------- | -------------------------------------------- | ------------------------------------------------ |
| Reconnaissance        | Identify exposed services and surface        | What scanning/enumeration looks like in logs     |
| Enumeration           | Map the application and find the weak point  | Web-log and service artifacts a hunter would see |
| Initial access        | Validate and exploit the vulnerability       | The CVE's detection and patch story              |
| Privilege escalation  | Move from user to root                       | The misconfiguration and how to audit for it     |
| Proof                 | Capture user/root proof (values redacted)    | —                                                |
| Remediation           | —                                            | The control that breaks the chain                |

Where relevant, findings are mapped to MITRE ATT&CK from the defender's perspective — the same
framing used across my defensive portfolio.

## Sanitization & safety

All write-ups are authored clean from the outset using a fixed placeholder scheme, then verified
through a layered, redundant gate before anything reaches the remote:

- Flag values are replaced with `[REDACTED]`; the *method* of obtaining each flag is documented, not
  the value.
- Operator identity and environment are normalized: `<operator>`, `/home/<operator>/...`,
  `<ATTACKER_IP>`, neutral shell prompts.
- Intended lab credentials (part of the machine's solution) are distinguished from operator/private
  credentials, which are never retained.
- Screenshots are captured with a neutral prompt and clean browser profile, metadata-stripped, and
  visually reviewed before staging.
- Enforcement is layered: pre-publication diff audit → custom sensitive-data audit + gitleaks →
  pre-commit hooks → server-side CI re-scan (authoritative).

Full details in [`SANITIZATION.md`](SANITIZATION.md).

## Disclaimer

This repository documents authorized penetration-testing exercises conducted exclusively against
intentionally vulnerable training environments. The write-ups demonstrate reconnaissance,
vulnerability validation, exploitation, privilege escalation, evidence handling, and remediation
analysis. No techniques are documented against systems outside explicitly
authorized training environments.

---

**Related project:** [Cybersecurity Investigations Portfolio](https://github.com/valeratech/cybersecurity-investigations-portfolio) — my primary defensive body of work (DFIR, SIEM, threat hunting, forensics).
