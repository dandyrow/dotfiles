# AGENTS.md

Before starting any task, review available skills and invoke any that apply.

## Golden Rules (MANDATORY)

- Respect the XDG Base Directory specification for all tool configuration, data, and cache paths. Override non-compliant defaults where necessary.
- Only comment to explain the non-obvious *why* — one line maximum, no restating what the code does. If a comment could be replaced by reading the next line, delete it. Describing what a variable holds, what a function's parameters mean, or what a block achieves are all forbidden.
- Root-cause analyses, falsified hypotheses, and link-outs to upstream issues belong in commit messages and PR bodies, not source comments.

## Working with Git

The following rules describe how you should use git:

- **Never work directly on `main`.** All work must happen in a worktree under `.worktrees/<branch>`.
- **Always start work via:** `./scripts/agent-start.sh <branch>`
- Inspect git and GitHub state directly. Do not rely on pre-expanded shell snippets.
- Use `git commit --no-gpg-sign` when committing.
- **Commit messages must use gitmoji + conventional commits format.**
- **Every commit body must include `Co-authored-by: Copilot <copilot@github.com>`** — appended automatically by the worktree hook.
- After a clean commit on a feature branch, push to `origin` and open a PR in the same turn.
- Keep PRs small and reviewable. Prefer multiple atomic commits.
- After a PR is confirmed merged, run `./scripts/agent-cleanup.sh <branch>` then `git pull` on `main`.

## Never do

- Never commit secrets, tokens, private keys, or `.env` files with secrets.
- Never rewrite history on `main`.
- Never use `git add -A` or `git add .`. Stage changes explicitly using file paths from status.
- Never delete unrelated files "for cleanup".
- Never run destructive commands without explicit instruction.
- Never act on an unanswered question, including across context compaction. Re-ask before acting.
- Do not silently create more than one PR for the same branch.
- Do not fabricate repository state; inspect it directly.
- Create verbose comments over multiple lines.

## Irreversible actions require explicit approval (MANDATORY)

**Requires explicit approval** (state intent first — "proceed" / "continue" is not approval):
- `gh pr merge`
- `nixos-rebuild switch`
- `git push` to `main`

**No approval needed** (act and report):
- `git push` / `git commit` / `git add <path>` on feature branches
- `gh pr create` / `gh pr view` / `gh pr checks` / `gh pr diff`
- `nix eval` / `nix build --no-link` / `nix flake check` / `nix-prefetch-url`
- Any read-only command (tests, linters, file reads)
- `agent-cleanup.sh <branch>` + `git pull main` when user confirms a PR is merged

## Agent skills

### Issue tracker

Issues live in GitHub Issues (`dandyrow/dotfiles`). See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout — `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

