# Nibbles — Proof of Objective Completion

> Flag values are intentionally redacted. Publishing flag strings defeats the purpose of the
> exercise for other learners and may trip acceptable-use filters. The *path* to each flag and the
> *method* used to obtain it are documented; the *value* is not. See
> [`SANITIZATION.md`](../../../SANITIZATION.md).

---

## User flag

| Item | Detail |
|---|---|
| **Path** | `/home/nibbler/user.txt` |
| **Access method** | Interactive shell as `nibbler` (uid 1001) via authenticated Nibbleblog file-upload RCE (CVE-2015-6967) |
| **Phase** | Initial access — [`exploitation/initial-access.md`](../exploitation/initial-access.md) |
| **Value** | `[REDACTED]` |

```
nibbler@Nibbles:/home/nibbler$ cat user.txt
[REDACTED]
```

---

## Root flag

| Item | Detail |
|---|---|
| **Path** | `/root/root.txt` |
| **Access method** | Privilege escalation from `nibbler` to `root` — pending |
| **Phase** | Privilege escalation — `privilege-escalation/privilege-escalation.md` (added at the privilege-escalation milestone) |
| **Value** | `[REDACTED]` |

*Root flag to be updated upon completion of the privilege-escalation phase.*
