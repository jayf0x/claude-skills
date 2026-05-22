# Adding a skill

## Plugin structure

```
plugins/<name>/
├── .claude-plugin/
│   └── plugin.json          # name, version, description, author, keywords
├── skills/
│   └── <name>/
│       ├── SKILL.md          # Claude's prompt for this skill (required)
│       └── scripts/          # helper scripts referenced from SKILL.md
├── commands/                 # slash commands
│   └── <cmd>.md or .toml
├── hooks/                    # PreToolUse / PostToolUse hook scripts
├── install.sh                # copies files to ~/.claude/skills/ and ~/.claude/commands/
└── uninstall.sh
```

## Steps

**1. Copy a template**

```bash
cp -r plugins/plan-next plugins/<your-skill>
```

**2. Update `plugin.json`**

Set `name`, `version`, `description`, `author`, `keywords`.

**3. Write `SKILL.md`**

Required frontmatter:
```yaml
---
name: <skill-name>
description: >
  What this skill does and when Claude should activate it.
  Include trigger phrases.
---
```

Then the instructions Claude follows when the skill runs.

**4. Write `install.sh` / `uninstall.sh`**

For skills with only a SKILL.md + scripts — copy to `~/.claude/skills/<name>/` and commands to `~/.claude/commands/`.

For hook-based skills (like `pause-claude-code`) — also patch `~/.claude/settings.json`. See [plugins/pause-claude-code/install.sh](plugins/pause-claude-code/install.sh).

**5. Register in marketplace**

Add an entry to `.claude-plugin/marketplace.json`:
```json
{
  "name": "<your-skill>",
  "source": "./plugins/<your-skill>",
  "description": "One line."
}
```

**6. Test**

```bash
./plugins/<your-skill>/install.sh
```

Then open Claude Code and verify the skill or command appears.
