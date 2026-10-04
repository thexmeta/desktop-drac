# T03 — Baseline Verification Results (material)

Branch: `linux` @ 52023946b11e0ec13859d312d91953b9c9a4b191
Purpose: Record CI-equivalent baseline (install + test + lint-critical) for post-migration T17 comparison.
Rule: Record only — never fix. Read-only on tracked files.

## 1. Environment snapshot

| Fact | Value |
|---|---|
| `node --version` | v24.18.1 |
| CI NODE_VERSION | 24.11.1 (ci-linux.yml env) — divergence noted |
| `git rev-parse HEAD` | 52023946b11e0ec13859d312d91953b9c9a4b191 |
| `git branch` | linux (not switched) |
| `git status --porcelain` (start) | `?? docs/plans/` (pre-existing untracked plan docs) |

## 2. CI command mapping (from .github/workflows/ci-linux.yml)

| Purpose | Exact command | Ref |
|---|---|---|
| Root install | `node vendor/yarn-1.21.1.js install --frozen-lockfile` | ci-linux.yml:47,76,143,214 |
| App install | No explicit CI step; root postinstall runs `node vendor/yarn-1.21.1.js --cwd app install --force` | script/post-install.ts:60 |
| Test | `node vendor/yarn-1.21.1.js test` | ci-linux.yml:79 |
| Lint-critical (task) | `node vendor/yarn-1.21.1.js run check:eslint` | package.json (`tsc -P eslint-rules/`) |
| CI lint job extras | `validate-electron-version`, `lint`, `validate-changelog`, clean-tree `git diff --name-status --exit-code` | ci-linux.yml:49-54 |

## 2b. Baseline summary table (T17 comparison inputs — extracted from artifacts/T03-baseline-verification.md)

| Step | Command | Exit code | Result |
|---|---|---|---|
| Root install | `node vendor/yarn-1.21.1.js install --frozen-lockfile` | **0** | PASS — frozen-lockfile OK; postinstall chain green (app install, electron, submodules, compile:script, patch-package); 247.72s |
| App install (CI-equivalent, via root postinstall) | (inside root install) | **0** | PASS — CI has no standalone app install step |
| App install (explicit standalone, bare PATH) | `node vendor/yarn-1.21.1.js --cwd app install --force` | **127** | BASELINE FINDING — `desktop-notifications` build needs `tsc` from root `node_modules/.bin`; bare PATH lacks it |
| App install (explicit, CI postinstall-equivalent PATH) | `PATH="$PWD/node_modules/.bin:$PATH" node vendor/yarn-1.21.1.js --cwd app install --force` | **0** | PASS — 4.44s |
| Tests (20min time-box; ~51s actual) | `node vendor/yarn-1.21.1.js test` | **1** | BASELINE FINDING (CI Tests job `continue-on-error: true`): **tests 1476 / suites 507 / pass 1461 / fail 14 / skipped 1**; all failures git-behavior suites |
| Lint-critical | `node vendor/yarn-1.21.1.js run check:eslint` (`tsc -P eslint-rules/`) | **2** | BASELINE FINDING: 5× TS2307 — `Cannot find module '@typescript-eslint/typescript-estree'` (moduleResolution) |
| Clean-tree | `git diff --name-status --exit-code` | **0** | CLEAN — no tracked files modified by any run |

**Test counts (baseline):** tests 1476 · suites 507 · pass 1461 · **fail 14** · skipped 1 · duration_ms 50913.4
**Failing suites (14, all git-behavior):** GitStore, git/checkout, git/commit, git/diff, git/for-each-ref, git/remote, git/status, parseFilesToBeOverwritten + submodule-diff variants.

## 3. Command transcripts

### 3.1 Root install (spec step 3)

Command: `node vendor/yarn-1.21.1.js install --frozen-lockfile`
Log: /tmp/opencode/t03-root-install.log (130 lines)

- **Exit code: 0** (Done in 247.72s total)
- `--frozen-lockfile` succeeded — NO manifest/lockfile drift on this branch (no retry needed)
- Root [4/4] linking succeeded; postinstall (script/post-install.ts) ran to completion:
  - app install (`--cwd app install --force`) — succeeded internally
  - electron install script — ran (no error in log)
  - `git submodule update --recursive --init` — ran (no error)
  - `compile:script` (`tsc -P script/tsconfig.json`) — "Done in 2.01s"
  - `patch-package` — "electron-installer-redhat@3.4.0 ✔ Done in 0.17s"
  - playwright ffmpeg install — ran; log shows no error for it
- Notable warnings (record only): `wrap-ansi@7.0.0` resolution incompatibility (known upstream note in check-upstream.yml), string-width-cjs unpack duplicate patterns, unmet peer `@types/react-dom` vs `@types/react` under `@testing-library/react`, optional-dep platform exclusions (fsevents, esbuild foreign archs, copilot foreign platform)
- **No tracked files modified** by root install (git diff empty)

### 3.2 App install (spec step 4)

CI has NO standalone app-install step; CI-equivalent app install is executed by root `postinstall` (script/post-install.ts:60) and succeeded as part of 3.1.

Explicit standalone invocation for recording:

Command A: `node vendor/yarn-1.21.1.js --cwd app install --force` (bare shell PATH)
- **Exit code: 127**
- Error: dependency `desktop-notifications` build script `node-gyp rebuild && tsc` → `/bin/sh: 1: tsc: not found`
- Root cause (record, not fix): `typescript` is a root-only devDependency; `app/node_modules/.bin/tsc` does not exist; bare PATH lacks root `node_modules/.bin`. In CI, this command only ever runs under root yarn-run lifecycle where PATH already includes root `node_modules/.bin/tsc`.

Command B: `PATH="$PWD/node_modules/.bin:$PATH" node vendor/yarn-1.21.1.js --cwd app install --force` (CI postinstall-equivalent PATH)
- **Exit code: 0** (Done in 4.44s) — lockfile save message present, no tracked file changes

### 3.3 Tests (spec step 5)

Command: `node vendor/yarn-1.21.1.js test`
Log: /tmp/opencode/t03-test.log (3155 lines)

- **Exit code: 1** — baseline finding, NOT a task failure (CI Tests job has `continue-on-error: true`)
- Runner summary (node:test, ~50.9s):

| Metric | Count |
|---|---|
| tests | 1476 |
| suites | 507 |
| pass | 1461 |
| fail | 14 |
| cancelled | 0 |
| skipped | 1 |
| todo | 0 |
| duration_ms | 50913.4 |

- Failing suites (14 tests, all git-behavior tests): `GitStore` (repository with HEAD file), `git/checkout` (can checkout a branch when it exists on multiple remotes), `git/commit` (createMergeCommit), `git/diff` (with submodules), `git/for-each-ref` (getBranches), `git/remote` (getRemotes), `git/status` (getStatus), `parseFilesToBeOverwritten` (parses files from pull error), plus submodule-diff variants (right paths / modified / untracked / commit change / all kinds), `can discard modified change cleanly`, `chooses their version of a file and commits`, `throws an error` (empty commit message GitError), `should return empty list for directory without a .git directory`, `returns empty array for directory without a .git directory`, `returns an empty array when there are no changes`, `returns the submodule status`
- Failure signatures observed: assertion mismatches in submodule status/diff counts (e.g. `3 == 1`), git error-path tests hitting real git behavior differences (GIT_DISCOVERY_ACROSS_FILESYSTEM not set, branch-overwrite Aborting, cannot pull with rebase: unstaged changes)
- Completed within 20min time-box (no partial capture needed)

### 3.4 Lint-critical — check:eslint (spec step 6)

Command: `node vendor/yarn-1.21.1.js run check:eslint` (= `tsc -P eslint-rules/`)
Log: /tmp/opencode/t03-eslint.log

- **Exit code: 2**
- Errors (5× TS2307, record only — NOT fixed per task rule): `eslint-rules/react-proper-lifecycle-methods.js` (13,14,15,16) and `eslint-rules/react-readonly-props-and-state.js` (17): `Cannot find module '@typescript-eslint/typescript-estree'` — types exist at `node_modules/@typescript-eslint/typescript-estree/dist/index.d.ts` but cannot resolve under current `moduleResolution` setting (tsc suggests `node16`/`nodenext`/`bundler`)
- Note: CI lint job does not run `check:eslint` directly; it runs `lint` (prettier + eslint-check + eslint). `check:eslint` is the task-specified T17 comparison point.

## 4. Clean-tree verification (spec step 7)

End-of-task `git status --porcelain`:

```
?? docs/plans/
?? material/
```

- `git diff --name-status --exit-code` → **exit 0** (no tracked files modified by any install/test/lint run)
- `?? docs/plans/` — pre-existing untracked plan infrastructure (present at task start, recorded in §1)
- `?? material/` — this task's own deliverable (baseline_results.md)
- **No tracked file was touched → nothing to restore** (install logs also showed `success Saved lockfile` from app-dir install without altering `yarn.lock` or `app/yarn.lock` in git)

## 5. Baseline findings for T17 (like-for-like comparison inputs)

1. Root install with `--frozen-lockfile`: **PASS (exit 0)** — lockfile in sync on linux branch; postinstall chain (app install, electron, submodules, compile:script, patch-package) all green.
2. App install standalone (bare PATH): **FAIL (exit 127)** due to `desktop-notifications` build needing `tsc` from root `node_modules/.bin`; succeeds (exit 0) when PATH matches CI postinstall context. T17 should compare against CI-context runs.
3. Tests: **14/1476 FAIL (exit 1)** — all git-behavior suites; matches CI reality (Tests job `continue-on-error: true`).
4. Lint-critical `check:eslint`: **FAIL (exit 2)** — 5× TS2307 moduleResolution errors for `@typescript-eslint/typescript-estree` in custom eslint-rules.
5. Environment divergences vs CI: local node v24.18.1 vs CI 24.11.1; local shell PATH lacks root bin dir (affects bare app-install invocation only).
6. Full transcripts: /tmp/opencode/t03-root-install.log, /tmp/opencode/t03-app-install.log, /tmp/opencode/t03-app-install-path.log, /tmp/opencode/t03-test.log, /tmp/opencode/t03-eslint.log

## 6. Materialization note (T14)

Materialized for wave-3 closeout (T14-deps-and-lockfile, wave-1 review Note 2 fix): summary table above (§2b) extracted from `artifacts/T03-baseline-verification.md` Run results (install/test/lint exit codes + test counts + CI command mapping). Full transcripts in §3. Baseline = old `linux` branch @ 52023946b11e0ec13859d312d91953b9c9a4b191 — post-migration T17 compares against THESE numbers, not green.
