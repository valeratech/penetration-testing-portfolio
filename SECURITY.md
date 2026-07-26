# Security & Responsible Use

## What this repository is

This repository contains **educational write-ups** of authorized penetration-testing exercises
performed exclusively against **intentionally vulnerable, retired training environments** (e.g.
retired Hack The Box machines). It documents methodology, reasoning, and defensive takeaways.

## What this repository is not

- It contains **no live secrets, credentials, keys, or tokens**. Any credential shown is an
  intended part of a retired lab's documented solution (see `SANITIZATION.md`, §3).
- It contains **no directly runnable exploit payloads**. Payload one-liners are defanged
  (placeholder host/port, bracketed shell metacharacters) so the technique is legible but not
  copy-paste executable (see `SANITIZATION.md`, §2).
- It documents **no activity against production, client, or non-consented systems.**

## Reporting a concern

If you believe any published material contains genuinely sensitive data (a real secret, a
non-lab IP or identity, an unredacted flag, or metadata in an image), please open an issue titled
`sensitivity report` **without** restating the sensitive value, or contact the maintainer directly.
Reports are triaged promptly and the content is removed or rewritten while the history is scrubbed.

## Handling of flags

Flag values (`user.txt`, `root.txt`) are intentionally redacted to `[REDACTED]` so readers solve
the boxes themselves and so raw hashes do not trip acceptable-use filters. The *path* to each flag
is documented; the *value* is not.
