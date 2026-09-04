# AGENTS.md

Before starting any task, review available skills and invoke any that apply.

## Golden Rules (MANDATORY)

- Respect the XDG Base Directory specification for all tool configuration, data, and cache paths. Override non-compliant defaults where necessary.
- Only comment to explain the non-obvious *why*, one line maximum, no restating what the code does. If a comment could be replaced by reading the next line, delete it. Describing what a variable holds, what a function's parameters mean, or what a block achieves are all forbidden.
  - Bad, multi-line, restates the code:
    ```nix
    # NIX_SSL_CERT_FILE is the only cert var in the impureEnvVars allowlist,
    # so it is the only way the corporate CA reaches FOD build sandboxes
    # (fetchCargoVendor's crates.io fetch) behind the TLS-intercepting proxy.
    ```
  - Good, one line, non-obvious *why* only:
    ```nix
    # Only cert var forwarded into FOD sandboxes — carries the corp CA past the proxy.
    ```
- Root-cause analyses, falsified hypotheses, and link-outs to upstream issues belong in commit messages and PR bodies, not source comments.
- Apply the `unslop` skill to all prose before finalizing: PR descriptions, issue bodies, commit messages, ADRs, comments.

## Working with Git

The following rules describe how you should use git:

- **Never edit files on `main`.** Read-only commands (`gh`, `git status`, `git log`, `nix eval`, `nix flake check`, etc.) are safe from the main checkout. Only file edits, moves, and creations require a worktree.
- **Always start work via:** `./scripts/agent-start.sh <branch>` before any file edit, move, or creation. If the task changes any tracked or stow-live file (including config under `opencode/`, `nix/`, or `~/.config` symlinks pointing into this repo), create the worktree first and make changes there, never in the `main` checkout. Only after `agent-start.sh` succeeds should you `cd` into the new worktree and edit.
- Inspect git and GitHub state directly. Do not rely on pre-expanded shell snippets.
- Use `git commit --no-gpg-sign` when committing. The flag is per-invocation and for agents only. GPG signing stays on normally, so never run `git config` to lower `commit.gpgSign` at repo or global scope, or unset a signing key. If signing blocks an automation step, pass `-c commit.gpgSign=false` for that command alone.
- Before staging, re-read the diff: every added comment must be a single line explaining a non-obvious *why*. Trim any that are not.
- **Commit messages must use gitmoji + conventional commits format.**
- **Every commit body must include `Co-authored-by: Copilot <copilot@github.com>`**, auto-appended by the worktree hook.
- After a clean commit on a feature branch, push to `origin` and open a PR in the same turn.
- Keep PRs small and reviewable. Prefer multiple atomic commits.
- After a PR is confirmed merged, run `./scripts/agent-cleanup.sh <branch>` then `git pull` on `main`.

## Never do

- Never edit, move, or create files in the `main` checkout, including files reached through `~/.config` symlinks that resolve into this repo. Read-only commands are fine from main. Always create and use a worktree for file modifications.
- Never commit secrets, tokens, private keys, or `.env` files with secrets.
- Never rewrite history on `main`.
- Never use `git add -A` or `git add .`. Stage changes explicitly using file paths from status.
- Never delete unrelated files "for cleanup".
- Never run destructive commands without explicit instruction.
- Never act on an unanswered question, including across context compaction. Re-ask before acting.
- Do not silently create more than one PR for the same branch.
- Do not fabricate repository state; inspect it directly.
- Never create verbose comments over multiple lines.

## Irreversible actions require explicit approval (MANDATORY)

**Requires explicit approval** (state intent first, "proceed" / "continue" is not approval):
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

Single-context layout: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

