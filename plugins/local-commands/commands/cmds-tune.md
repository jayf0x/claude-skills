# /cmds-tune — audit whether the harvest filters are well-tuned

Check whether `extract-commands.py`'s default filters (`EXCLUDE_RE`, min/max length) are dropping commands that would actually have been cheatsheet-worthy, or letting through too much noise. This is a filter-quality audit, not a normal collect/harvest run.

## Steps

1. Run the mechanical diff — no judgment yet, just extraction:

```bash
python3 ~/.claude/cache/local-commands/scripts/harvest_diff.py --every-project
```

   This runs `extract-commands.py` twice — once with the default filters, once with a much more permissive exclude list and length range — and prints only the commands the *default* pass throws away that the *generous* pass keeps (tab-prefixed with occurrence count, most-repeated first). These are the false negatives to review.

2. Read the list. For each command, judge it exactly as `/cmds-collect` would: is this a transferable technique (non-obvious flag, tool gotcha, machine-specific fix), or is it noise (project paths, one-off greps, standard commands)? You don't have session context here — judge from the command text alone, same as `/cmds-harvest`.

3. Compare your findings to the current filters in `extract-commands.py` (`EXCLUDE_RE`, `DEFAULT_MIN_LEN`, `DEFAULT_MAX_LEN`):
   - If most of the diff is noise → filters are fine, or could even be tightened. Say so.
   - If several genuinely useful commands were being dropped → identify *why* (matched an exclude pattern too eagerly, exceeded max length, etc.) and propose a specific, narrow fix — not a wholesale loosening. Show the proposed diff to `extract-commands.py`.

4. If you found a real problem and the user agrees with the fix, apply it directly with Edit, then re-run step 1 to confirm the specific false negatives are now captured (without a flood of new noise).

5. Report: how many commands were reviewed, how many were genuine misses, what (if anything) changed.

This is a manual, occasional audit — run it when you suspect the filters are off, not on a schedule. For an unattended version that loops via the `claude` CLI and can edit the script itself, see `scripts/harvest.test.py`.
