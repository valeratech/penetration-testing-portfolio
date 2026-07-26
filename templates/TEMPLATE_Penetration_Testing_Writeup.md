# Penetration Testing Write-up Template

> A write-up for the **retired** Hack The Box machine *&lt;NAME&gt;*. Retired machines are approved
> for public publication under HTB's content-sharing rules.

> ℹ️ **Defanging & redaction note.** Lab IPs are RFC 1918 / HTB lab space and are defanged
> (`10.10.10.10` → `10[.]10[.]10[.]10`, `http://` → `hxxp://`) only for filter compatibility, not
> for safety. Executable payloads are neutralized (placeholder host/port, bracketed metacharacters).
> Operator identity is `<operator>`; flag values are `[REDACTED]`. **Re-fang only in an authorized
> lab.** See `SANITIZATION.md`.

**Case Title:**
**Box / Case ID:**
**Platform:**  Hack The Box
**Publication status:**  Retired — cleared for publication
**Date Created:**
**Last Updated:**
**Author:**
**Time Standard:**  UTC

---

## 1. Overview

### Objective
What this exercise sets out to achieve (initial access, privilege escalation to root, etc.).

### Scope & Authorization
Authorized, intentionally vulnerable training target. No activity outside the lab.

### Attack-path summary
One or two sentences, filled in **only when the box is complete** (kept out of per-phase commits so
the narrative is not spoiled early).

---

## 2. Environment & Tools

- Target: `<name>` (`OS`, difficulty)
- Attack VM: Kali (`<operator>`), VPN `<ATTACKER_IP>`
- Tools: nmap, gobuster/feroxbuster, whatweb, curl, netcat, ... (per phase)

---

## 3. Methodology (offensive → defensive)

Document each phase with its defensive lens. Add the phase files as the milestones progress.

| Phase                 | Offensive objective                     | Defensive lens                              |
| --------------------- | --------------------------------------- | ------------------------------------------- |
| Reconnaissance        | Identify exposed services               | What the scan looks like in logs            |
| Enumeration           | Find the weak point                     | Artifacts a hunter would see                |
| Initial access        | Validate & exploit                      | The CVE's detection and patch story         |
| Privilege escalation  | User → root                             | The misconfiguration and how to audit it    |
| Proof                 | Capture user/root proof (`[REDACTED]`)  | —                                           |
| Remediation           | —                                       | The control that breaks the chain           |

---

## 4. Findings

Concise, evidence-backed findings per phase (link to the phase files under `recon/`,
`exploitation/`, `privilege-escalation/`).

---

## 5. MITRE ATT&CK mapping (defender's view)

| Tactic | Technique | ID | Where observed |
| ------ | --------- | -- | -------------- |

---

## 6. Defensive takeaways / Remediation

The detection opportunities and the specific controls that break this chain (see `remediation.md`).

---

## 7. References

Advisories, tool docs, and research consulted (see `references/sources.md`).

---

## 8. Disclaimer

This write-up documents an authorized penetration-testing exercise conducted exclusively against an
intentionally vulnerable training environment. No techniques are documented against systems outside
explicitly authorized training environments.
