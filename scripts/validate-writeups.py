#!/usr/bin/env python3
"""
validate-writeups.py — content-integrity checks for published write-ups (stdlib only).

Verifies, per Markdown write-up under a box directory:
  * defanging consistency  — no bare http(s)://, no bare lab IP written without [.]
  * flag hygiene           — proof/ files never contain a bare 32-hex flag value
  * structure              — a write-up carries a defanging/retired note
  * link resolution        — relative Markdown links point at files that exist

Usage:  python3 scripts/validate-writeups.py --check [path]     (default path: .)
Exit :  0 = all checks pass     1 = one or more failures
"""
import os, re, sys

BARE_URL   = re.compile(r'https?://')
BARE_LABIP = re.compile(r'(?<![\[\d.])(?:10|127|192\.168|172\.(?:1[6-9]|2\d|3[01]))\.\d{1,3}\.\d{1,3}(?:\.\d{1,3})?')
HEX32      = re.compile(r'\b[0-9a-f]{32}\b')
CHECKSUM   = re.compile(r'md5|sha|checksum|integrity|fingerprint', re.I)
MDLINK     = re.compile(r'\[[^\]]+\]\(([^)]+)\)')
NOTE_HINT  = re.compile(r'defang|retired', re.I)
# Control docs and templates DOCUMENT the defanging convention (they contain http:// -> hxxp://
# mapping examples), so the bare-URL/IP checks do not apply to them.
CONTROL    = re.compile(r'(^|/)(SECURITY|SANITIZATION|CONTRIBUTING)\.md$|/templates/')

def is_control(path):
    if CONTROL.search(path):
        return True
    # root-level README (not a box README) also documents conventions
    base = os.path.basename(path)
    return base == 'README.md' and 'hack-the-box' not in path and 'tryhackme' not in path

def md_files(root):
    for dp, _, fns in os.walk(root):
        if '.git' in dp:
            continue
        for fn in fns:
            if fn.endswith('.md'):
                yield os.path.join(dp, fn)

def check_file(path):
    problems = []
    with open(path, encoding='utf-8', errors='replace') as fh:
        lines = fh.readlines()
    text = ''.join(lines)
    in_box = os.sep + 'hack-the-box' + os.sep in path
    is_proof = os.sep + 'proof' + os.sep in path
    defang_exempt = is_control(path)

    for i, line in enumerate(lines, 1):
        # A line that already shows a defanged twin ([.] or hxxp) is documenting the
        # convention (e.g. the defanging note panel), not violating it.
        if not defang_exempt and BARE_URL.search(line) and 'hxxp' not in line:
            problems.append(f'{path}:{i}: bare URL (use hxxp/hxxps): {line.strip()[:90]}')
        if not defang_exempt and BARE_LABIP.search(line) and '[.]' not in line:
            problems.append(f'{path}:{i}: bare lab IP (defang with [.]): {line.strip()[:90]}')
        if is_proof and HEX32.search(line) and not CHECKSUM.search(line) and 'REDACTED' not in line:
            problems.append(f'{path}:{i}: possible unredacted flag in proof/: {line.strip()[:90]}')

    # box write-ups (not the box README, not stubs) should carry a defanging/retired note
    if in_box and os.path.basename(path) != 'README.md' and len(text) > 400:
        if not NOTE_HINT.search(text):
            problems.append(f'{path}: missing defanging/retired note')

    # relative links resolve
    base = os.path.dirname(path)
    for tgt in MDLINK.findall(text):
        tgt = tgt.split('#', 1)[0].strip()
        if not tgt or tgt.startswith(('http', 'hxxp', 'mailto:')):
            continue
        if not os.path.exists(os.path.normpath(os.path.join(base, tgt))):
            problems.append(f'{path}: broken relative link -> {tgt}')
    return problems

def main():
    args = [a for a in sys.argv[1:] if a != '--check']
    root = args[0] if args else '.'
    all_problems = []
    for f in md_files(root):
        all_problems.extend(check_file(f))
    if all_problems:
        print('VALIDATION FAILED:')
        for p in all_problems:
            print('  ' + p)
        return 1
    print('VALIDATION PASSED')
    return 0

if __name__ == '__main__':
    sys.exit(main())
