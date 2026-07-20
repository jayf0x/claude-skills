#!/usr/bin/env python3
"""Self-check for the local-commands harvest filters — NOT a pytest test.
Named harvest.test.py because it's a standalone review/tuning run, not
something meant to be invoked interactively as a skill (see /cmds-tune for
that). This one shells out to `claude` and can edit extract-commands.py.

What it does, up to --max-iterations times:
  1. Run harvest_diff.py: find commands the default filter drops that a
     generous pass would have kept.
  2. If the count is <= --threshold, the filters are good enough. Stop.
  3. Otherwise, hand the diff to `claude -p` and ask it to judge whether
     the filter is over-excluding and, if so, make a narrow edit to
     extract-commands.py (EXCLUDE_RE / length bounds). Permission mode is
     capped to acceptEdits — it can edit files, nothing else — since that's
     all this task needs.
  4. Re-run the diff and repeat.

Every edit lands in the working tree, never committed. Nothing here runs
`git commit` or `git push`. Review with `git diff` / discard with
`git checkout -- extract-commands.py` if the changes aren't right.

Usage:
  harvest.test.py [--every-project] [--threshold N] [--max-iterations N]

Costs real API calls: each iteration that doesn't converge invokes the
`claude` CLI once. Run manually, not on a schedule.
"""
import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DIFF_SCRIPT = SCRIPT_DIR / "harvest_diff.py"
TARGET = SCRIPT_DIR / "extract-commands.py"

DEFAULT_THRESHOLD = 5
DEFAULT_MAX_ITERATIONS = 3

PROMPT_TEMPLATE = """You are auditing the filter quality of a command-extraction script used to \
build a personal shell-command cheatsheet.

{target} extracts Bash commands from Claude Code session transcripts and \
filters out noise using EXCLUDE_RE, DEFAULT_MIN_LEN, and DEFAULT_MAX_LEN.

Below are commands that the DEFAULT filter drops but a much more permissive \
pass keeps (tab-prefixed with occurrence count, most-repeated first). These \
are false negatives: candidates that might be genuinely cheatsheet-worthy \
(non-obvious flags, tool gotchas, machine-specific fixes) but are being \
thrown away.

Judge each command the way a careful curator would: is it a transferable \
technique, or is it noise (project-specific paths, one-off greps, standard \
commands with extra args)? You have no session context — judge from the \
command text alone.

If most of this list is noise, the filter is fine as-is — do NOT edit \
anything just to force a change.

If you find genuine misses, make the SMALLEST possible edit to {target} \
that fixes them (e.g. narrow one exclude pattern, don't gut EXCLUDE_RE; \
raise DEFAULT_MAX_LEN only if length was the actual cause). Do not loosen \
filters generically "to be safe" — every loosening lets more noise into a \
file that's re-read every session.

Ignored-but-plausible commands:
{diff_output}

When you're done (whether or not you edited anything), write your verdict \
to {verdict_path} as a single JSON object on one line:
{{"edited": true/false, "reason": "one sentence"}}
"""


def run_diff(every_project: bool) -> tuple[str, int]:
    args = [sys.executable, str(DIFF_SCRIPT)]
    if every_project:
        args.append("--every-project")
    proc = subprocess.run(args, capture_output=True, text=True, check=True)
    lines = [l for l in proc.stdout.splitlines() if l.strip()]
    return proc.stdout, len(lines)


def invoke_claude(diff_output: str, verdict_path: Path) -> dict:
    prompt = PROMPT_TEMPLATE.format(
        target=TARGET, diff_output=diff_output, verdict_path=verdict_path
    )
    proc = subprocess.run(
        ["claude", "-p", prompt, "--permission-mode", "acceptEdits"],
        capture_output=True, text=True, cwd=str(SCRIPT_DIR),
    )
    if proc.returncode != 0:
        return {"edited": False, "reason": f"claude CLI failed (exit {proc.returncode}): {proc.stderr[:300]}"}
    if not verdict_path.exists():
        return {"edited": False, "reason": "claude did not write a verdict file"}
    try:
        return json.loads(verdict_path.read_text().strip())
    except (json.JSONDecodeError, ValueError):
        return {"edited": False, "reason": "verdict file was not valid JSON"}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--every-project", action="store_true")
    ap.add_argument("--threshold", type=int, default=DEFAULT_THRESHOLD)
    ap.add_argument("--max-iterations", type=int, default=DEFAULT_MAX_ITERATIONS)
    args = ap.parse_args()

    original = TARGET.read_text()
    report = []

    for i in range(1, args.max_iterations + 1):
        diff_output, count = run_diff(args.every_project)
        report.append(f"iteration {i}: {count} ignored-but-plausible commands (threshold {args.threshold})")

        if count <= args.threshold:
            report.append(f"iteration {i}: within threshold, stopping")
            break

        with tempfile.TemporaryDirectory() as tmp:
            verdict_path = Path(tmp) / f"verdict-{i}.json"
            verdict = invoke_claude(diff_output, verdict_path)

        report.append(f"iteration {i}: claude verdict — edited={verdict.get('edited')}, reason={verdict.get('reason')}")

        if not verdict.get("edited"):
            report.append(f"iteration {i}: no edit made, no point re-running — stopping")
            break
    else:
        report.append(f"stopped after {args.max_iterations} iterations without converging")

    final = TARGET.read_text()
    changed = final != original

    print("\n".join(report))
    print()
    if changed:
        print(f"extract-commands.py was modified. Changes are in your working tree, NOT committed.")
        print(f"Review: git diff -- {TARGET}")
        print(f"Discard: git checkout -- {TARGET}")
    else:
        print("extract-commands.py was not modified.")


if __name__ == "__main__":
    main()
