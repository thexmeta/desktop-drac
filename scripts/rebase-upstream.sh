#!/usr/bin/env bash
# rebase-upstream.sh — one-command upstream sync for the rebase-stack workflow.
# Local-only: never pushes, never force-pushes, never touches backup refs.
set -euo pipefail

OLD_BASE="${1:-release-3.6.6}"
BACKUP_TAG="backup/linux-merge-era-20261004"

cd "$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: worktree dirty — commit/stash first." >&2
  exit 1
fi

if ! git rev-parse -q --verify "refs/tags/${BACKUP_TAG}" >/dev/null; then
  echo "ERROR: safety tag ${BACKUP_TAG} missing — aborting." >&2
  exit 1
fi

git fetch desktop --tags

LATEST=$(git tag -l 'release-*' --sort=-v:refname | head -1)
if [ -z "$LATEST" ]; then
  echo "ERROR: no release-* tags found on desktop remote." >&2
  exit 1
fi

if [ "$LATEST" = "$OLD_BASE" ]; then
  echo "Already up to date: stack base ${OLD_BASE} == latest ${LATEST}."
  exit 0
fi

TARGET="stack/${LATEST}"
if git rev-parse -q --verify "refs/heads/${TARGET}" >/dev/null; then
  echo "Branch ${TARGET} already exists at $(git rev-parse --short "${TARGET}"). Nothing to do."
  exit 0
fi

echo "Rebasing stack commits from ${OLD_BASE} onto ${LATEST}..."
git branch "$TARGET" "$LATEST"
if git rebase --onto "$LATEST" "$OLD_BASE" stack/3.6.6; then
  echo "Done. New stack tip: $(git log --oneline -1)"
  echo "Review, then push manually: git push fork ${TARGET}"
else
  echo ""
  echo "CONFLICTS — resolve, then: git rebase --continue"
  echo "Contract: main.ts = merge-file, preserve confirm-reveal-directory;"
  echo "package.json = 3-way, never checkout linux's copy;"
  echo "lockfiles = regenerate with 'node vendor/yarn-1.21.1.js install', never hand-edit."
  exit 1
fi
