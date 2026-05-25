#!/usr/bin/env bash
set -euo pipefail

# scripts/agent-cleanup <branch>
#
# Tears down a merged feature branch: removes the worktree under
# .worktrees/<flattened-branch>, prunes worktree metadata, and deletes
# the local branch. Must be run from the main worktree (not from inside
# the worktree being removed).
#
# Safety:
# - Refuses to run from inside .worktrees/.
# - Refuses to delete a branch whose remote has not been deleted, unless
#   --force is passed.

BRANCH="${1:-}"
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
  esac
done

if [[ -z "${BRANCH}" || "${BRANCH}" == --* ]]; then
  echo "Usage: $0 <branch> [--force]"
  echo "Example: $0 fix/wsl-sbx-shim-segfault"
  exit 1
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Error: not inside a git repository."
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel)"

# Refuse to run from inside .worktrees/. The current directory would be
# pulled out from under us when the worktree is removed.
case "$ROOT" in
  */.worktrees/*)
    echo "Error: refuse to run from inside a worktree. cd to the main checkout first."
    exit 1
    ;;
esac

cd "$ROOT"

WORKTREE_NAME="${BRANCH//\//-}"
TARGET_DIR="$ROOT/.worktrees/$WORKTREE_NAME"

# Update remote tracking so the merged-remote check below is accurate.
git fetch --prune origin --quiet || true

# Verify the branch was actually merged. If origin/<branch> still exists
# the PR has not been merged-and-deleted yet; bail unless --force.
if [[ "$FORCE" -ne 1 ]]; then
  if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
    echo "Error: origin/$BRANCH still exists. Merge the PR (which deletes the remote branch) first, or re-run with --force."
    exit 1
  fi
fi

# Remove the worktree if present.
if [[ -d "$TARGET_DIR" ]]; then
  git worktree remove "$TARGET_DIR"
  echo "✅ Removed worktree: $TARGET_DIR"
else
  echo "ℹ️  No worktree at $TARGET_DIR (already gone)."
fi

git worktree prune

# Delete the local branch. Use -D because squash-merged branches are not
# recognised as merged by git's -d check.
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git branch -D "$BRANCH"
  echo "✅ Deleted local branch: $BRANCH"
else
  echo "ℹ️  No local branch '$BRANCH' (already gone)."
fi

echo ""
echo "Cleanup complete."
