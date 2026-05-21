# AGENTS.md — Dotfiles + Nix Repo Agent Operating Manual

This repository contains:
- System dotfiles (shell/editor/tool configs)
- Nix configuration for various systems under `nix/`
- `flake.nix` and `flake.lock` at repository root

This file is the source of truth for how coding agents must operate in this repo.

---

## Golden Rules (MANDATORY)

1. **Never work directly on `main`.** All work must happen in a worktree under `.worktrees/<branch>`.
2. **Always start work via:** `./scripts/agent-start.sh <branch>`
3. **Commit messages MUST be Gitmoji + Conventional Commits:**
   `<emoji> <type>(optional-scope): <description>`
4. **Attribution rule:** agent-created commits MUST include a `Co-authored-by:` trailer identifying the AI agent (see [AI Co-Author Attribution](#ai-co-author-attribution-must)).
5. Keep PRs small and reviewable. Prefer multiple atomic commits.
6. Inspect git and GitHub state directly. Do not rely on pre-expanded shell snippets.

---

## Worktree Workflow (MANDATORY)

```bash
# Create worktree + install hooks
./scripts/agent-start.sh <branch>

# Work inside the worktree
cd .worktrees/<branch>

# Push and open PR
git push -u origin <branch>
# then open a PR into main via gh or GitHub UI

# Cleanup (from repo root)
git worktree remove .worktrees/<branch> && git worktree prune
```

---

## Commit Message Standard (STRICT)

Format: `<emoji> <type>(optional-scope): <description>`

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `build`, `perf`, `style`

Examples:
- `✨ feat(nix): add devShell for tooling`
- `🔧 chore(dotfiles): add git aliases`
- `🐛 fix(zsh): prevent duplicate PATH entries`

---

## AI Co-Author Attribution (MUST)

Every agent-created commit must include a `Co-authored-by:` trailer that identifies the specific AI agent:

```
Co-authored-by: <Agent Name> <agent-email@example.com>
```

Use the identity appropriate for the agent doing the work. The `agent-start.sh` script installs a commit-msg hook that appends this automatically. Override the identity by setting env vars before calling the script:

```bash
AI_COAUTHOR_NAME="My Agent" AI_COAUTHOR_EMAIL="agent@example.com" \
  ./scripts/agent-start.sh <branch>
```

Rules:
- Do not change the commit author identity to the AI identity.
- Do not add additional co-authors unless explicitly requested.

---

## Rules

### Nix changes
- Prefer minimal, reproducible changes.
- Keep Nix-related edits within `nix/` where possible.
- If you change flake outputs, ensure they remain consistent and valid.
- If you change flake inputs, update the flake lockfile.

### Dotfiles changes
- Keep changes scoped and minimal; avoid large refactors unless requested.
- Do not introduce secrets (tokens, private keys, machine-specific secrets).

### Never do
- Never commit secrets, tokens, private keys, or `.env` files with secrets.
- Never rewrite history on `main`.
- Never use `git add -A` or `git add .`. Stage changes explicitly using file paths from status.
- Never delete unrelated files "for cleanup".
- Never run destructive commands without explicit instruction.
- Do not silently create more than one PR for the same branch.
- Do not fabricate repository state; inspect it directly.

---

## If uncertain
Ask a short clarifying question rather than guessing. Follow existing patterns in this repo.
