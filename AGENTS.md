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
7. **Never act on an unanswered question.** If you asked the user whether to proceed with something and no explicit answer was received — including across a context compaction boundary — re-ask before acting. A compaction summary does not constitute user consent.

---

## Worktree Workflow (MANDATORY)

```bash
# Create worktree + install hooks
./scripts/agent-start.sh <branch>

# Work inside the worktree (slashes in the branch name are preserved as
# nested directories, e.g. branch "fix/foo-bar" → .worktrees/fix/foo-bar)
cd .worktrees/<branch>

# Push and open PR
git push -u origin <branch>
gh pr create --fill --base main
```

After a clean commit on a feature branch in a worktree, **push to `origin` and open the PR in the same turn**. Pushing a feature branch and opening a PR are not destructive and do not require explicit user approval. Wait for approval only for the actions listed under [Irreversible actions](#irreversible-actions-require-explicit-approval-mandatory) (notably: merging the PR, `nixos-rebuild switch`, deleting branches/worktrees, and any push to `main`).

After a PR is merged, `./scripts/agent-cleanup.sh <branch>` removes the worktree, prunes worktree metadata, and deletes the local branch in one step. **Running this is the agent's responsibility once the PR is confirmed merged**, but because it deletes a branch and a worktree it requires explicit user approval per the irreversible-actions rule — propose it and wait.

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

Every agent-created commit must include a `Co-authored-by:` trailer identifying the AI agent. **The commit-msg hook installed by `agent-start.sh` appends this automatically — you do not need to write it manually.**

Default identity (when no env vars are set): `Co-authored-by: Copilot <copilot@github.com>`

To use a different identity, set env vars before calling the script:

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
- **Bumping a vendored package** (anything under `nix/pkgs/`): follow the recipe in [`.github/instructions/nix-version-bumps.instructions.md`](.github/instructions/nix-version-bumps.instructions.md). It covers prefetch → vendor → stage → eval → build → version-check → commit → push + PR, plus common `autoPatchelfHook` failure modes. Copilot CLI loads this file automatically when editing `nix/pkgs/**` or `flake.nix`; other agents should read it explicitly.

### Dotfiles changes
- Keep changes scoped and minimal; avoid large refactors unless requested.
- Do not introduce secrets (tokens, private keys, machine-specific secrets).

### XDG Base Directory compliance
All tool configuration and data paths must follow the XDG Base Directory specification:
- Config: `~/.config/<tool>/`
- Data: `~/.local/share/<tool>/`
- Cache: `~/.cache/<tool>/`

When configuring a tool or plugin that writes to a custom path (e.g. a save directory, cache location, or data store), verify it uses the appropriate XDG directory rather than a legacy dotfile path (e.g. `~/.tool/`). Override the default if necessary.

### Never do
- Never commit secrets, tokens, private keys, or `.env` files with secrets.
- Never rewrite history on `main`.
- Never use `git add -A` or `git add .`. Stage changes explicitly using file paths from status.
- Never delete unrelated files "for cleanup".
- Never run destructive commands without explicit instruction.
- Do not silently create more than one PR for the same branch.
- Do not fabricate repository state; inspect it directly.

### Irreversible actions require explicit approval (MANDATORY)

Before executing any of the following actions, **state what you are about to do and
wait for explicit confirmation in the current user message**. Generic phrases such as
"continue", "proceed", or "go ahead with next steps" do NOT constitute approval.

Actions that require explicit approval:
- Merging a pull request (`gh pr merge`)
- Running `nixos-rebuild switch` (activates a new system generation)
- Any `git push` to `main`

Actions that do **not** require explicit approval (do them and report — asking permission for these wastes a turn):
- `git push` to a feature branch (anything except `main`)
- `gh pr create` / `gh pr view` / `gh pr checks` / `gh pr diff`
- Creating, reading, editing, or staging files inside a worktree
- `git add <path>` (explicit paths only — never `-A` or `.`)
- `git commit` on a feature branch
- `nix eval` / `nix build --no-link` / `nix flake check` / `nix-prefetch-url`
- Running tests, linters, formatters, or any read-only inspection command
- `./scripts/agent-cleanup.sh <branch>` — when the user states that a PR has been merged
  (e.g. "that PR is merged", "the PRs are merged"), that statement is implicit approval
  to immediately run cleanup for the relevant branch(es) without asking again.

---

## If uncertain
Ask a short clarifying question rather than guessing. Follow existing patterns in this repo.

---

## Repo map

When a task touches files described in this map, read those files directly. Do **not** re-explore the tree with `ls`/`find`/`glob`/`grep` to confirm what the map already states — that wastes tool calls and tokens. Only fall back to exploration if the task involves paths not covered here, or if you have specific reason to believe the map is out of date.

| Path | Purpose |
| --- | --- |
| `flake.nix` / `flake.lock` | Flake entry. `nixosConfigurations`: `WSL`, `DansSpectre`, `New-H0Ryzen`. |
| `nix/hosts/<host>/` | Per-host NixOS configuration (entrypoint: `configuration.nix`). |
| `nix/home/` | Home-manager configuration shared across hosts. |
| `nix/modules/{common,desktop,profiles}/` | Reusable NixOS modules composed by hosts. |
| `nix/pkgs/` | Repo-local package derivations (e.g. `docker-sbx.nix`), exposed via `pkgs` overlay. |
| `scripts/agent-start.sh` | Creates the per-branch worktree and installs the co-author hook. |
| `scripts/agent-cleanup.sh` | Removes a merged branch's worktree and local branch in one step. |
| `scripts/ai-commit` | Optional wrapper around `git commit` for agent commits. |
| `.worktrees/<branch>/` | Active agent worktrees (slashes in the branch name are preserved as nested directories — `fix/foo` lives at `.worktrees/fix/foo`). Removed by `agent-cleanup.sh` after the user confirms the PR is merged. |

Non-Nix dotfiles (shell, editor, tool configs) live at the repo root and under conventional `XDG_CONFIG_HOME` paths.

---

## Environment facts

- **Hosts:** the flake provides three NixOS configurations — `WSL` (NixOS-WSL2), `DansSpectre`, `New-H0Ryzen`. Detect the current host before assuming behaviour. The `$HOST` shell variable is the default way to read the hostname and can be used inline in commands (e.g. `nix build .#nixosConfigurations.$HOST...`). Fall back to `cat /etc/hostname` only if `$HOST` is unset.
- **WSL-only specifics:** on `WSL` the kernel comes from the Windows side, not Nix; `/etc/nixos/corp.pem` may be present for the corporate CA (referenced via `builtins.pathExists`), which means rebuilds need `nixos-rebuild switch --flake .#WSL --impure`. These do not apply to `DansSpectre` or `New-H0Ryzen`.
- **Working baselines for cross-distro debugging:** on `WSL` an Ubuntu/WSL2 install on the same Windows host is available as a side-by-side reference. On other hosts, compare against a previous working generation (`nix profile history`, `/run/current-system` vs the proposed build) instead.
- **GPG signing fails non-interactively** (`gpg: cannot open '/dev/tty'`) in agent sessions. Use `git commit --no-gpg-sign` unless the user provides another path.
- **GitHub:** `gh` is authenticated. Inspect PRs/issues/checks directly rather than guessing.

---

## Verification expectations

The flake uses the **git tree** as its source of truth. `nix eval`, `nix build`, and `nix flake check` cannot see untracked files — a newly written `.nix` file will produce a "path does not exist" error until it is staged. Stage new files with `git add <path>` (explicit paths only) immediately after writing them, before any `nix` evaluation or build.

Before claiming a Nix change is correct:

- `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` must succeed.
- For changed packages: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link` (or build the specific derivation) must succeed.
- Behavioural changes that only manifest after `nixos-rebuild switch` (services, kernel modules, runtime binaries) **cannot be agent-verified end-to-end**. State this explicitly in the PR and propose the post-switch commands the user should run.

Never claim "this fixes X" on the strength of a successful eval alone when X is a runtime symptom.

---

## Debugging discipline

For non-trivial runtime failures (services crashing, packages misbehaving, mounts/perms issues), invoke the `systematic-debugging` skill before proposing a fix.

- Treat the **first** ERROR in a log as the root cause candidate, not the most visible one. Downstream errors are often misleading (e.g. an `EACCES` mount error that's actually downstream of a segfaulting helper).
- When a working baseline exists (other host running the same package, a parallel non-NixOS install, a previous generation), diff against it before hypothesising.
- If the user reports a previous fix did not work, ask for the new failure mode before proposing the next change. Do not chain hypotheses without evidence.
- Falsified hypotheses get recorded in the PR description / commit message so we don't re-run them next time.

---

## Style notes

- **Default: no comment.** Only add a comment when the code cannot convey the *why* on its own. If you are unsure whether a comment is needed, omit it.
- When a comment is warranted, keep it to one line. Do not restate what the code does; explain only the non-obvious reason it does it.
- Root-cause analyses, falsified hypotheses, and link-outs to upstream issues belong in commit messages and PR bodies, not in source comments.
- Prefer hoisting repeated literals (versions, hashes, URLs) into `let` bindings or attributes so they update in one place.
