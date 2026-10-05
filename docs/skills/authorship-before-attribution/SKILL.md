---
id: authorship-before-attribution
name: Authorship Before Attribution
description: "Before treating a fork delta, branch, or merge as the user's custom work for migration, extraction, or PR scoping — verify who authored each commit."
metadata:
  version: "1.0"
  confidence: high
  source: task-20261004-rebase-upstream-stack
  usages: 0
---

## When to Apply

You are about to describe a fork delta, branch, or merge as "the user's custom work" —
e.g., re-extracting "user features," scoping a PR/migration, or attributing a branch's
purpose. A "fork delta" is not "the user's custom work."

## Steps

1. **Build an attribution table.** Run `git log --format='%an <%ae>' <range>` across the
   delta under review, then across each contributing commit and branch tip
   (`git log <tip> --not <baseline>`). Record author name + email per commit.
2. **Separate commits by author.** Group the table by author identity. Count commits and
   changed files per author. Flag any commit whose author is not the user.
3. **Confirm scope with the user.** Ask an explicit question that lists every author found
   and their commit counts (e.g., "delta has 41 commits: 18 by you, 23 by xi72yow — which
   are yours?"). Never assume fork features are the user's work.
4. **Treat unmerged WIP branches as candidate genuine work — verify authorship there too.**
   The user's real contributions often live in unmerged WIP branches; inspect those with
   the same attribution table before excluding them from scope.

## Evidence Anchor

A migration re-extracted an 85-file fork delta as "user features"; the user replied
"none of them mine." 23 of the delta commits were authored by a different person (xi72yow),
and the user's genuine work (TheMeta) lived in unmerged WIP branches — plan scope had to
be revised mid-plan.

## Common Edge Cases

- Branch names imply purpose but the commits say otherwise — attribute by author first.
- Unmerged WIP branches look redundant; check their authors before dropping them.
- Mixed-author deltas: never label the whole delta "the user's" when any foreign author exists.
