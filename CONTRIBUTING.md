# Contributing / Workflow

This is a personal portfolio, but it follows a disciplined, reproducible publication workflow so the
sanitization guarantees in `SANITIZATION.md` always hold. The workflow doubles as the narrative
engine: each write-up is committed **in solve order**, so `git log --reverse` reads like a first-time
solve while `main` always shows the finished case.

## The gated pipeline

```text
author (clean placeholders)
  → diff-audit (source vs. defanged notes vs. staged file)
  → package + sha256 (transfer integrity)
  → git add + pre-commit (local gate: audit + gitleaks + hygiene + image metadata)
  → git commit (substantive, non-spoiling message)
  → git push + CI (authoritative re-scan; look for "SECURITY GATES PASSED")
```

## Running the gates locally

```bash
# one-time
pip install pre-commit && pre-commit install
# per change
bash scripts/audit-sensitive-data.sh .          # custom PII/secret/payload audit
python3 scripts/validate-writeups.py --check .   # defanging + structure + link checks
bash scripts/inspect-images.sh hack-the-box       # EXIF / metadata review on staged images
pre-commit run --all-files                        # runs the whole local gate
```

Confirm the push passed CI by tying the commit SHA to its run:

```bash
git push && sleep 5
SHA=$(git log --oneline -1 | cut -d' ' -f1)
RUN=$(gh run list -L5 --json databaseId,headSha -q ".[] | select(.headSha|startswith(\"$SHA\")) | .databaseId")
gh run watch "$RUN" && gh run view "$RUN" --log | grep -F 'SECURITY GATES PASSED'
```

## Commit conventions

- Conventional prefixes: `docs:`, `feat:`, `chore:`, `fix:`.
- **Non-spoiling:** a commit subject/body must not reveal findings from a *later* phase. The recon
  commit does not name the CVE; the foothold commit does not name the privesc path; etc.
- State in the body that sensitive values are held outside the repo, not committed.

## Milestone sequence (per box)

```text
scaffold → reconnaissance → enumeration → initial access → user proof
        → privilege escalation → root proof → remediation → final documentation
```

Each milestone adds only the file(s) for that phase and grows the box `README.md` only up to the
knowledge available at that stage.

## Structure of a box directory

```text
hack-the-box/<box>/
├── README.md                 # box overview (grows per milestone; non-spoiling until done)
├── recon/                    # nmap, service enumeration
├── exploitation/             # initial access, shell notes
├── privilege-escalation/     # privesc path
├── proof/                    # flag capture (values redacted)
├── screenshots/              # metadata-stripped images
├── references/               # advisories, tools, research
└── remediation.md            # defensive takeaways (added at the remediation milestone)
```
