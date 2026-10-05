---
name: wip-branch-coverage-audit
description: "When about to skip/rebase/merge a WIP branch, or when a branch name implies work that may not exist — audit actual content before planning around it."
metadata:
  version: "1.0"
  confidence: high
  source: task-memory-update
  usages: 0
---

# WIP Branch Coverage Audit

Branch names lie; "redundant" is not a proof. Audit content before you skip or plan.

## When to Apply

- Before any skip / rebase / merge decision on a WIP or stale branch.
- When a branch name implies scope you have not verified exists.
- When a branch "seems already covered" by the current stack.

## Steps

1. **Inspect unique commits — never trust the branch name.** List commits in the tip
   but not the baseline, then grep for name-implied keywords BEFORE planning around the
   branch's apparent purpose:
   ```
   git log --oneline <wip-tip> --not <baseline>
   git log --format='%h %s' <wip-tip> --not <baseline> | grep -i '<name-keywords>'
   ```
   Zero keyword matches ⇒ the name is stale; treat the branch as a generic snapshot.

2. **When a branch seems redundant, classify every file via byte-diff** vs the target,
   using exactly these labels:
   - `IDENTICAL` — `git diff <wip> <target> -- <file>` is empty
   - `LINT-ONLY` — eslint/prettier/formatting only; zero logic changes
   - `ADDITIVE` — target adds behavior the WIP branch lacks (unrelated)
   - `LOST` — behavior exists ONLY in the WIP branch

3. **Skip ONLY when every unique commit maps to IDENTICAL or LINT-ONLY.** Any `LOST`
   row means behavior would be dropped — layer it onto the target or escalate for a
   port decision. Never skip on a name or a hunch; skip on the table.

4. **Record the classification table as acceptance evidence** (commit list, grep
   output, per-file table: file → classification → command) in the plan's logs or
   material directory. An unrecorded audit is not an audit.

## Evidence

- `deb-build-all` contained **zero** deb commits: exactly 3 unique commits, a
  byte-identical composite of repo-pinning + protocol-URL work — stale name.
- `pr7-lockfix` + `protocol-url-handling` proven covered by `stack/3.6.6`: every hunk
  classified IDENTICAL / LINT-ONLY / ADDITIVE; zero LOST behavior → correctly skipped;
  only `repo-pinning` was layered.

## Edge Cases

- Copied tips: `git diff <sibling-a> <sibling-b> --stat` empty ⇒ byte-identical.
- Large `git rev-list --count <tip>..<upstream>` distance is irrelevant for skipped
  branches; traverse only for branches you keep.

## References

- Evidence: `docs/plans/20261004-rebase-upstream-stack/material/WIP-branches-deep-map.md`
- Learnings #2/#3: `docs/plans/20261004-rebase-upstream-stack/logs/memory_update.md`
