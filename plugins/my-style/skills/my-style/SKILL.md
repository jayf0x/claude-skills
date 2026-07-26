---
name: my-style
description: >
  Personal React/frontend code style and philosophy, active in every session.
  Consult before writing or reviewing React components, hooks, or file
  structure. Also handles the /my-style command: no args loads this skill,
  "add <text>" appends a rule to the cache, "merge" reconciles cache into
  memory.
---

Two files live in this skill's installed directory (next to this SKILL.md):
`memory.md` (active rules) and `cache.md` (unreviewed additions).

## Default behavior (no command)

Before writing or reviewing React code, read `memory.md` and follow it. If a
rule doesn't fit the case at hand, use judgment, deviate, and say so — then
suggest `/my-style add "<rule>"` if the deviation seems worth capturing.

## `/my-style` (no args)

Just read `memory.md` so its rules are active for this session. Confirm
briefly which rules are loaded.

## `/my-style add <content>`

1. Read both `cache.md` and `memory.md`.
2. If `<content>` is a duplicate or near-duplicate of an existing entry in
   either file, say so and skip — don't append.
3. Otherwise append `<content>` as a new bullet/section to `cache.md`.

## `/my-style merge`

1. Read `cache.md` and `memory.md`.
2. For each cache entry, decide: keep (promote to memory.md), drop
   (contradicts or is superseded by an existing rule), or ask the user when
   it's a judgment call.
3. Write the kept entries into `memory.md`, then clear `cache.md` back to its
   empty template.
4. Summarize what was kept/dropped in one short list.
