# local-commands

Mines your own session history for useful shell/CLI commands and compresses them into a cheat-sheet skill that's injected into every future session.

## Install

```bash
./plugins/local-commands/install.sh
```

Restart Claude Code after installing.

## Use

```
/cmds-collect    # dump the current session's useful commands
/cmds-harvest    # backfill from past session transcripts
/cmds-compress   # compress all collected dumps into the active cheat sheet
/cmds-tune       # audit whether the harvest filters are well-tuned
```

Typical flow: run `/cmds-harvest` once to backfill history, then `/cmds-collect` at the end of sessions going forward, and `/cmds-compress` periodically to fold everything into the cheat sheet.

## Uninstall

```bash
./plugins/local-commands/uninstall.sh
```
