#!/usr/bin/env python3
"""Extract Bash tool_use commands from Claude Code session transcript(s).

Mechanical extraction only — no dedup-by-similarity, no judgment calls.
That's left to the agent, which has full conversation context.

Usage:
  extract-commands.py                  # current session only (needs
                                        # CLAUDE_CODE_SESSION_ID + cwd)
  extract-commands.py --all            # every transcript for this project
  extract-commands.py --all --every-project
  extract-commands.py --session-id ID --project-dir /path/to/project
"""
import argparse
import json
import os
import re
import sys
from pathlib import Path

DEFAULT_MIN_LEN = 10
DEFAULT_MAX_LEN = 200

# Commands so standard that no agent needs them saved. Matches the *start*
# of the command string.
EXCLUDE_RE = re.compile(
    r"^(ls|cat|cd|pwd|echo|git (status|log|diff|add|commit|push|pull)\b"
    r"|npm (install|test|run)\b|mkdir|rm|cp|mv|grep|find|which|head|tail"
    r"|wc|chmod)\b"
)


def project_dir_from_cwd(cwd: str) -> str:
    # Claude Code's convention: absolute path with / and . replaced by -
    escaped = re.sub(r"[/.]", "-", cwd)
    return str(Path.home() / ".claude" / "projects" / escaped)


def iter_transcript_paths(args) -> list[Path]:
    projects_root = Path.home() / ".claude" / "projects"

    if args.session_id and not args.all:
        pdir = Path(args.project_dir) if args.project_dir else Path(
            project_dir_from_cwd(os.getcwd())
        )
        return [pdir / f"{args.session_id}.jsonl"]

    if args.every_project:
        return sorted(projects_root.glob("*/*.jsonl"))

    if args.all:
        pdir = Path(args.project_dir) if args.project_dir else Path(
            project_dir_from_cwd(os.getcwd())
        )
        return sorted(pdir.glob("*.jsonl"))

    # default: current session only
    pdir = Path(args.project_dir) if args.project_dir else Path(
        project_dir_from_cwd(os.getcwd())
    )
    sid = args.session_id or os.environ.get("CLAUDE_CODE_SESSION_ID")
    if not sid:
        print(
            "error: no session id (set CLAUDE_CODE_SESSION_ID or pass --session-id, "
            "or use --all to scan every transcript for this project)",
            file=sys.stderr,
        )
        sys.exit(1)
    return [pdir / f"{sid}.jsonl"]


def extract_commands(paths: list[Path]) -> list[str]:
    commands = []
    for path in paths:
        if not path.exists():
            continue
        with path.open(errors="ignore") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                content = record.get("message", {}).get("content")
                if not isinstance(content, list):
                    continue
                for block in content:
                    if (
                        isinstance(block, dict)
                        and block.get("type") == "tool_use"
                        and block.get("name") == "Bash"
                    ):
                        cmd = block.get("input", {}).get("command")
                        if isinstance(cmd, str):
                            commands.append(cmd.strip())
    return commands


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--session-id", help="Session id (default: $CLAUDE_CODE_SESSION_ID)")
    ap.add_argument("--project-dir", help="Override project transcript dir")
    ap.add_argument("--all", action="store_true", help="Scan all sessions for this project")
    ap.add_argument("--every-project", action="store_true", help="Scan all sessions, all projects")
    ap.add_argument("--min-len", type=int, default=DEFAULT_MIN_LEN)
    ap.add_argument("--max-len", type=int, default=DEFAULT_MAX_LEN)
    ap.add_argument(
        "--exclude-re",
        default=None,
        help="Override the built-in noise-exclusion regex (matched against the "
        "start of each command). Pass '' to disable exclusion entirely.",
    )
    ap.add_argument(
        "--sort",
        choices=["chrono", "freq"],
        default="chrono",
        help="chrono: first-seen order (best for a single session). "
        "freq: most-repeated first (best across many sessions).",
    )
    args = ap.parse_args()

    if args.exclude_re is None:
        exclude_re = EXCLUDE_RE
    elif args.exclude_re == "":
        exclude_re = None
    else:
        exclude_re = re.compile(args.exclude_re)

    paths = iter_transcript_paths(args)
    raw = extract_commands(paths)

    # exact-match dedup only; count occurrences, keep first-seen order
    seen: dict[str, int] = {}
    order: list[str] = []
    for cmd in raw:
        if len(cmd) < args.min_len or len(cmd) > args.max_len:
            continue
        if exclude_re is not None and exclude_re.match(cmd):
            continue
        if "\n" in cmd:  # multi-line scripts/heredocs: rarely cheatsheet material
            continue
        if cmd not in seen:
            order.append(cmd)
        seen[cmd] = seen.get(cmd, 0) + 1

    if args.sort == "freq":
        order.sort(key=lambda c: seen[c], reverse=True)

    for cmd in order:
        print(f"{seen[cmd]}\t{cmd}")

    print(
        f"# {len(raw)} raw commands, {len(order)} after filtering "
        f"(len {args.min_len}-{args.max_len}, noise excluded, exact-dupes merged) "
        f"from {len(paths)} transcript(s)",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
