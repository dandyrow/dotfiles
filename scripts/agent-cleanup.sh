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

parse_branch "$@"

resolve_root
require_main_worktree
cd "$ROOT"

# Find the worktree path for this branch via porcelain output, which
# parses as paired `worktree <path>` / `branch refs/heads/<name>` lines.
# Returns empty if no worktree is associated with the branch.
TARGET_DIR="$(find_worktree_path "$BRANCH")"

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

# Remove the worktree if one is registered for this branch.
if [[ -n "$TARGET_DIR" ]]; then
  git worktree remove "$TARGET_DIR"
  echo "✅ Removed worktree: $TARGET_DIR"

  # Clean up newly-empty parent directories — but only when the worktree
  # lived strictly inside $ROOT/.worktrees/. Worktrees in other locations
  # (created with a custom path) are left alone; rmdir'ing arbitrary
  # parents outside .worktrees/ is not this script's job.
  #
  # The trailing slash in the prefix is load-bearing: it means
  # $ROOT/.worktrees itself never matches, so the loop terminates
  # naturally at the .worktrees/ boundary without needing extra checks.
  if [[ "$TARGET_DIR" == "$ROOT/.worktrees/"* ]]; then
    cleanup_empty_parents "$TARGET_DIR"
  fi
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
