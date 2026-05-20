#!/usr/bin/env bash
# plan-context.sh
# Reads ~/.claude/projects/ to find session history for the current repo,
# extracts first/last messages from recent sessions, and reads the plan file.
# Output is structured text for Claude to parse.
#
# Usage: plan-context.sh [stage-arg]
#   stage-arg: "next" (default), "a", "b", "c", "1", "2", etc.

set -uo pipefail

ARGUMENT="${1:-next}"

# ── 1. Locate current project ──────────────────────────────────────────────
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Claude encodes project paths by replacing / with - (leading slash becomes leading -)
ENCODED_PATH=$(echo "$GIT_ROOT" | sed 's|/|-|g')
PROJECTS_DIR="${HOME}/.claude/projects"
PROJECT_DIR="${PROJECTS_DIR}/${ENCODED_PATH}"

echo "=== PLAN-NEXT CONTEXT ==="
echo "PROJECT_ROOT: $GIT_ROOT"
echo "REQUESTED_STAGE: $ARGUMENT"
echo ""

# ── 2. Find plan/config file ───────────────────────────────────────────────
PLAN_FILE=""
PLAN_FILE_NAME=""
for name in plan.md PLAN.md Plan.md stages.md STAGES.md CLAUDE.md claude.md TODO.md todo.md; do
    if [[ -f "${GIT_ROOT}/${name}" ]]; then
        PLAN_FILE="${GIT_ROOT}/${name}"
        PLAN_FILE_NAME="$name"
        break
    fi
done

if [[ -n "$PLAN_FILE" ]]; then
    echo "=== PLAN FILE: $PLAN_FILE_NAME ==="
    cat "$PLAN_FILE"
    echo ""
else
    echo "=== PLAN FILE: none found ==="
    echo "(no plan.md, CLAUDE.md, stages.md, or TODO.md in repo root)"
    echo ""
fi

# ── 3. Recent git activity ─────────────────────────────────────────────────
echo "=== RECENT GIT LOG ==="
git -C "$GIT_ROOT" log --oneline -8 2>/dev/null || echo "(no git history)"
echo ""

# ── 4. Read session history ────────────────────────────────────────────────
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "=== SESSION HISTORY ==="
    echo "No session history found at: $PROJECT_DIR"
    echo "(This may be a new project or the path encoding may differ)"
    exit 0
fi

# Find non-agent JSONL files, sorted newest-first
mapfile -t SESSION_FILES < <(
    find "$PROJECT_DIR" -maxdepth 1 -name "*.jsonl" ! -name "agent-*" \
        -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn \
    | awk '{print $2}' \
    | head -5
)

if [[ ${#SESSION_FILES[@]} -eq 0 ]]; then
    echo "=== SESSION HISTORY ==="
    echo "No session files found in $PROJECT_DIR"
    exit 0
fi

echo "=== SESSION HISTORY (last ${#SESSION_FILES[@]} sessions) ==="

python3 - "${SESSION_FILES[@]}" <<'PYEOF'
import json, sys, os

def get_text(content):
    """Extract plain text from Claude message content (str or content-block list)."""
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get('type') == 'text':
                t = block.get('text', '').strip()
                if t:
                    parts.append(t)
        return ' '.join(parts)
    return ''

def read_session(path):
    """Return list of (role, text) for human/assistant turns."""
    turns = []
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue
                
                msg_type = obj.get('type', '')
                
                # Handle both "human"/"assistant" and "user"/"assistant" conventions
                if msg_type in ('human', 'user'):
                    role = 'user'
                elif msg_type == 'assistant':
                    role = 'assistant'
                else:
                    continue
                
                # Content can be at top level or inside .message
                raw = (obj.get('message') or {}).get('content') or obj.get('content', '')
                text = get_text(raw)
                
                # Skip empty, very short, or tool-only turns
                if len(text) < 10:
                    continue
                
                turns.append((role, text))
    except Exception as e:
        pass
    return turns

files = sys.argv[1:]
for i, path in enumerate(files):
    turns = read_session(path)
    session_name = os.path.basename(path)
    session_label = f"Session {i+1}" + (" (most recent)" if i == 0 else "")
    
    print(f"\n--- {session_label} [{session_name}] ---")
    
    if not turns:
        print("  (no readable turns)")
        continue
    
    # First user message
    first_user = next((t for role, t in turns if role == 'user'), None)
    if first_user:
        preview = first_user[:250].replace('\n', ' ')
        print(f"  OPENING PROMPT: {preview}")
    
    # Last few turns to understand what was finished
    tail = turns[-4:]
    print(f"  CLOSING TURNS ({len(turns)} total turns):")
    for role, text in tail:
        preview = text[:200].replace('\n', ' ')
        print(f"    [{role.upper()}]: {preview}")

PYEOF

echo ""
echo "=== END CONTEXT ==="
