Use the my-style skill.

Argument: $ARGUMENTS

- If empty: load the skill with no other action (the "no args" case in SKILL.md).
- If it starts with "add " (or "add\n"): the rest is the content to append —
  follow the `/my-style add <content>` case in SKILL.md.
- If it is "merge": follow the `/my-style merge` case in SKILL.md.
- Anything else: treat the whole argument as content for "add".
