#!/usr/bin/env python3
"""Find commands the default extract-commands.py filter throws away that a
much more permissive pass would have kept.

Pure mechanical diff, no LLM calls. Two other things consume this:
  - the /cmds-tune skill (interactive: an agent reads the output and judges it
    directly, using its own reasoning, no subprocess)
  - harvest.test.py (standalone: shells out to `claude -p` to judge it)

Usage:
  harvest_diff.py [--every-project]

Prints ignored-but-plausible commands, most-repeated first, one per line
(tab-prefixed with the generous-pass occurrence count). Prints a one-line
count summary to stderr.
"""
import argparse
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
EXTRACT = SCRIPT_DIR / "extract-commands.py"

# Much more permissive than extract-commands.py's default EXCLUDE_RE: only
# drops genuinely bare, no-argument invocations. Everything else (git/npm
# with flags, longer one-liners, etc.) survives, so the diff against the
# default pass shows what the default filter is throwing away.
GENEROUS_EXCLUDE_RE = r"^(ls|cat|cd|pwd|echo|mkdir|rm|cp|mv|grep|find|which|head|tail|wc|chmod)$"
GENEROUS_MIN_LEN = "4"
GENEROUS_MAX_LEN = "500"


def run_extract(extra_args: list[str]) -> dict[str, int]:
    out = subprocess.run(
        [sys.executable, str(EXTRACT), *extra_args],
        capture_output=True, text=True, check=True,
    ).stdout
    counts: dict[str, int] = {}
    for line in out.splitlines():
        if line.startswith("#"):
            continue
        count_str, _, cmd = line.partition("\t")
        if cmd:
            counts[cmd] = int(count_str)
    return counts


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--every-project", action="store_true", help="Scan all projects, not just this one")
    args = ap.parse_args()

    scope = ["--every-project"] if args.every_project else ["--all"]

    generous = run_extract([
        *scope, "--sort", "freq",
        "--min-len", GENEROUS_MIN_LEN, "--max-len", GENEROUS_MAX_LEN,
        "--exclude-re", GENEROUS_EXCLUDE_RE,
    ])
    default = run_extract([*scope, "--sort", "freq"])

    ignored = sorted(
        (cmd for cmd in generous if cmd not in default),
        key=lambda c: generous[c],
        reverse=True,
    )

    for cmd in ignored:
        print(f"{generous[cmd]}\t{cmd}")

    print(
        f"# {len(ignored)} commands the default filter drops that a generous pass keeps "
        f"(generous pool: {len(generous)}, default pool: {len(default)})",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
