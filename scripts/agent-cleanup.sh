#!/usr/bin/env bash
# scripts/agent-cleanup <branch>
#
# Tears down a merged feature branch: removes the worktree (if one is
# associated with the branch), prunes worktree metadata, deletes the
# local branch, and removes any newly-empty parent directories under
# .worktrees/. Must be run from the main worktree (not from inside the
# worktree being removed).
#
# Worktree lookup uses `git worktree list --porcelain` keyed on branch
# name, so the on-disk path layout is not assumed. This works for the
# current slash-preserving convention and is robust to future changes.
#
# Safety:
# - Refuses to run from inside .worktrees/.
# - Refuses to delete a branch whose remote has not been deleted, unless
#   --force is passed.

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=worktree.sh
source "$SELF_DIR/worktree.sh"

parse_branch --allow-force "$@"

resolve_root
require_main_worktree
cd "$ROOT"

TARGET_DIR="$(find_worktree_path "$BRANCH")"

# Refresh remote tracking so the merged-remote check below is accurate.
git fetch --prune origin --quiet || true

# Bail unless --force: origin/<branch> still existing means the PR is not merged-and-deleted yet.
if [[ "$FORCE" -ne 1 ]]; then
  if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
    echo "Error: origin/$BRANCH still exists. Merge the PR (which deletes the remote branch) first, or re-run with --force."
    exit 1
  fi
fi

if [[ -n "$TARGET_DIR" ]]; then
  git worktree remove "$TARGET_DIR"
  echo "✅ Removed worktree: $TARGET_DIR"

  cleanup_empty_parents "$TARGET_DIR"
else
  echo "ℹ️  No worktree associated with branch '$BRANCH' (already gone or never existed)."
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
