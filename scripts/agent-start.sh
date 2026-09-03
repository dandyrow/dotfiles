#!/usr/bin/env bash
# scripts/agent-start <branch>
#
# Creates a worktree at .worktrees/<branch> based on origin/main and
# configures worktree-local hooks to ensure AI co-author attribution.
#
# Branch names containing slashes (e.g. "feat/foo") are preserved as nested
# directories under .worktrees/ (e.g. .worktrees/feat/foo). Companion script
# agent-cleanup.sh uses `git worktree list --porcelain` to locate worktrees
# by branch name, so the on-disk path layout is not assumed.

SELF_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=worktree.sh
source "$SELF_DIR/worktree.sh"

parse_branch "$@"

# --- configurable AI co-author trailer (override via env vars) ---
AI_COAUTHOR_NAME="${AI_COAUTHOR_NAME:-Copilot}"
AI_COAUTHOR_EMAIL="${AI_COAUTHOR_EMAIL:-copilot@github.com}"
AI_TRAILER="Co-authored-by: ${AI_COAUTHOR_NAME} <${AI_COAUTHOR_EMAIL}>"

resolve_root
require_main_worktree
cd "$ROOT"

# Base branches off a freshly-fetched origin/main, not a stale local copy.
git fetch origin main --quiet || {
  echo "Error: failed to fetch origin/main. Check your remotes."
  exit 1
}

WORKTREES_DIR="$ROOT/.worktrees"
TARGET_DIR="$WORKTREES_DIR/$BRANCH"

mkdir -p "$WORKTREES_DIR"

if [[ -d "$TARGET_DIR" ]]; then
  echo "Error: worktree directory already exists: $TARGET_DIR"
  echo "If it's stale, run: git worktree remove \"$TARGET_DIR\" && git worktree prune"
  exit 1
fi

# Create the worktree and new branch from origin/main
git worktree add -b "$BRANCH" "$TARGET_DIR" "origin/main"

# Configure the co-author hook only inside this worktree, via worktree-local hooksPath
(
  cd "$TARGET_DIR"

  # Store the trailer in a file so the hook can grep it out of each commit message
  cat > .ai-coauthor.txt <<EOF
${AI_TRAILER}
EOF

  mkdir -p .githooks

  # commit-msg hook: append the co-author trailer if missing
  cat > .githooks/commit-msg <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

MSG_FILE="$1"
TRAILER_FILE=".ai-coauthor.txt"

if [[ ! -f "$TRAILER_FILE" ]]; then
  exit 0
fi

TRAILER="$(cat "$TRAILER_FILE")"

if ! grep -Fq "$TRAILER" "$MSG_FILE"; then
  printf "\n%s\n" "$TRAILER" >> "$MSG_FILE"
fi
EOF
  chmod +x .githooks/commit-msg

  # Enable hooks for this worktree only
  git config core.hooksPath .githooks
)

echo ""
echo "✅ Worktree created:"
echo "   $TARGET_DIR"
echo ""
echo "✅ AI co-author attribution configured for this worktree:"
echo "   $AI_TRAILER"
echo "   (Auto-appended via worktree-local commit-msg hook)"
echo ""
echo "Next steps:"
echo "  1) cd \"$TARGET_DIR\""
echo "  2) Make changes"
echo "  3) git add <explicit-paths>"
echo "  4) git commit --no-gpg-sign -m \"✨ feat(scope): message\""
echo "  5) git push -u origin \"$BRANCH\""
echo "  6) Open a PR to main"
