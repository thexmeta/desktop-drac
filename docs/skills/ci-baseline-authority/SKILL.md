---
id: ci-baseline-authority
name: CI Baseline Authority
description: "Use when local lint/test failures appear on a supposedly CI-green commit, when adopting a newer upstream lockfile, or when CI node-version pins must be verified before pushing."
metadata:
  version: "1.0"
  confidence: high
  source: task-memory_update-20261004-rebase-upstream-stack
  usages: 0
---

## When to Apply

- Local `yarn lint` or `yarn test` fails on a commit you believe is CI-green.
- You adopted, or are about to adopt, a newer upstream `yarn.lock`.
- You changed a CI workflow node-version pin.

## Steps

1. **Triage lint failures by path ownership — CI-irrelevant noise first.**
   - Cross-reference failing lint paths against `git status --porcelain`.
   - Untracked paths (e.g. `docs/plans/**` YAML migration byproducts) are never linted by CI. Do not "fix" them.
   - Verify with a direct binary check on tracked paths only: `./node_modules/.bin/prettier --check <tracked-paths>`.
   - Only format what that check flags.
   - *Evidence:* local `yarn lint` (prettier glob) kept failing after tracked files were fixed; the failures were untracked `docs/plans/**` byproducts; CI was green on the same code.

2. **Treat the CI test job as the authoritative release gate — never "fix to green" locally.**
   - When the local suite fails on a commit that is green on CI, do not patch local code to silence it.
   - Compare counts and failure-class lists, not just pass/fail: local full suite = 14 git-behavior failures (documented T03/T17 host-harness artifact); CI Tests job on the same commit = 0 failures (pinned node 24.15.0).
   - Trust CI for the release gate; keep the local delta documented (host, harness, node version).
   - A local failure class that CI never exhibits is a host artifact until proven otherwise — not a regression.

3. **Validate node pins against the upstream lockfile before pushing.**
   - Grep `engines` of major deps in the lockfile you are adopting: `grep -A2 '^<pkg>@' yarn.lock`.
   - Compare each `engines` range against every CI workflow node pin and the repo `.nvmrc`. All pins must satisfy the strictest range found.
   - *Evidence:* fork ci-linux.yml pinned NODE_VERSION 24.11.1; upstream release-3.6.6 lockfile carried `ini@7.0.0` requiring `^22.22.2||^24.15.0||>=26.0.0` → every CI job died at install. The ini entry was identical on the upstream base (not stack-introduced). Fix: bump the pin to 24.15.0, aligned with `.nvmrc`.
   - An `engines` conflict that originates on the upstream base is not a merge defect — fix the pin, never revert the adopted lockfile.

## Common Edge Cases

- `yarn lint` fails but `./node_modules/.bin/prettier --check` on tracked paths passes → the script's glob is sweeping untracked directories; rule 1 applies.
- CI fails at install immediately after a lockfile adoption → run rule 3 before suspecting the merge itself.
- Local failures cluster in git-behavior suites → expect host-harness artifacts; record the count (e.g. the 14-vs-0 delta), do not chase them.

## References

- See [docs/plans/20261004-rebase-upstream-stack/logs/memory_update.md] learnings #5–#7 for full LEARNING → EVIDENCE → REUSE RULE chains.
