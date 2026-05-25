#!/usr/bin/env bash
set -euo pipefail

# scripts/agent-start <branch>
#
# Creates a worktree at .worktrees/<branch> based on origin/main and
# configures worktree-local hooks/helpers to ensure AI co-author attribution.

BRANCH="${1:-}"

if [[ -z "${BRANCH}" ]]; then
  echo "Usage: $0 <branch>"
  echo "Example: $0 feat/nix-devshell"
  exit 1
fi

# --- configurable AI co-author trailer (override via env vars) ---
# If you ever want OpenCode-specific attribution, change these defaults.
AI_COAUTHOR_NAME="${AI_COAUTHOR_NAME:-Copilot}"
AI_COAUTHOR_EMAIL="${AI_COAUTHOR_EMAIL:-copilot@github.com}"
AI_TRAILER="Co-authored-by: ${AI_COAUTHOR_NAME} <${AI_COAUTHOR_EMAIL}>"

# --- sanity checks ---
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Error: not inside a git repository."
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

# Ensure we can base branches off origin/main
git fetch origin main --quiet || {
  echo "Error: failed to fetch origin/main. Check your remotes."
  exit 1
}

WORKTREES_DIR="$ROOT/.worktrees"
# Flatten branch names like "chore/foo" into "chore-foo" so worktrees live
# directly under .worktrees/ rather than in type-prefixed subdirectories.
WORKTREE_NAME="${BRANCH//\//-}"
TARGET_DIR="$WORKTREES_DIR/$WORKTREE_NAME"

mkdir -p "$WORKTREES_DIR"

if [[ -d "$TARGET_DIR" ]]; then
  echo "Error: worktree directory already exists: $TARGET_DIR"
  echo "If it's stale, run: git worktree remove \"$TARGET_DIR\" && git worktree prune"
  exit 1
fi

# Create the worktree and new branch from origin/main
git worktree add -b "$BRANCH" "$TARGET_DIR" "origin/main"

# Configure hook + helper scripts in the worktree only
(
  cd "$TARGET_DIR"

  # Store trailer in a file for reuse
  cat > .ai-coauthor.txt <<EOF
${AI_TRAILER}
EOF

  # Worktree-local hooks directory
  mkdir -p .githooks

  # commit-msg hook: append trailer if missing
  cat > .githooks/commit-msg <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

MSG_FILE="$1"
TRAILER_FILE=".ai-coauthor.txt"

if [[ ! -f "$TRAILER_FILE" ]]; then
  exit 0
fi

TRAILER="$(cat "$TRAILER_FILE")"

# Append trailer if not already present
if ! grep -Fq "$TRAILER" "$MSG_FILE"; then
  printf "\n%s\n" "$TRAILER" >> "$MSG_FILE"
fi
EOF
  chmod +x .githooks/commit-msg

  # Enable hooks for this worktree only
  git config core.hooksPath .githooks

  # Helper script: explicit "agent commit" command
  mkdir -p scripts
  cat > scripts/ai-commit <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/ai-commit \"<emoji> <type>(scope): message\""
  exit 1
fi

MSG="$1"

# Ensure staged changes exist
if git diff --cached --quiet; then
  echo "No staged changes. Stage files first (git add ...)."
  exit 1
fi

# Commit with a title + trailer body.
git commit -m "$MSG" -m "$(cat .ai-coauthor.txt)"
EOF
  chmod +x scripts/ai-commit

  # Reminder doc
  cat > .AI_WORKFLOW.md <<EOF
# Worktree Workflow Reminder

You are in a git worktree under \`.worktrees/\`.

Rules:
- Do NOT commit on main.
- Commit format: \`<emoji> <type>(optional-scope): <description>\`
- Agent commits MUST include:
  ${AI_TRAILER}

This worktree auto-appends the trailer via a local commit-msg hook.

Common flow:
  git add -A
  scripts/ai-commit "✨ feat(nix): add devShell"
EOF
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
echo "  3) Commit (either):"
echo "       - scripts/ai-commit \"✨ feat(scope): message\""
echo "       - or git commit (hook will append trailer automatically)"
echo "  4) git push -u origin \"$BRANCH\""
echo "  5) Open a PR to main"
