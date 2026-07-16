# Nix-native dependency workflow

Machine-global guidance for every AI agent operating on these NixOS machines. Never modify the system in a way Nix can't reproduce. No global `npm i -g`, `pip install`, `cargo install`, `go install`, `curl | sh`, or any other imperative, out-of-Nix install. When you need a tool, either run it ephemerally through Nix or propose adding it to the Nix config — never install it imperatively.

This file is the source of truth for the workflow and is loaded outside any single repo. Repo-specific rules live in that repo's own `AGENTS.md`; this file never overrides them and they never restate it.

## Scope

This governs **system and CLI tools** — executables you'd reach for on the command line (formatters, linters, language servers, CLIs, interpreters needed as ambient tools).

It does **not** govern **project-local language dependencies** — packages a project declares for itself (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`). Installing those into the project's own tree is normal and off the ladder: `npm ci`, `npm install <pkg>` in a project, `pip install -r requirements.txt` inside a project venv, `cargo build`, `go build`. The line: does the tool belong to *the machine/your session* (on the ladder) or to *the project you're working in* (off it)?

## The dependency decision ladder

**Trigger:** an unmet tool-need — you reach for a system/CLI tool that isn't on `PATH`. Reaching for an **install-class command** (`npm i -g`, `pip install`, `pipx install`, `cargo install`, `go install`, `nix profile install`, `nix-env -i`, `curl … | sh`) to satisfy that need is the **named anti-pattern**; stop and walk the ladder instead.

1. **Discover.** Find which Nix package provides the tool with `nix-locate <binary>` (e.g. `nix-locate bin/rg`). This maps a missing command to its `nixpkgs` attribute.

2. **Prefer a project environment.** If the project defines its own environment, use it rather than reaching to the machine: `nix develop` for a flake devShell, or `nix-shell shell.nix` for a legacy shell. (Note: `direnv` is not available here, so environments are entered explicitly, not auto-loaded.) Only climb past this rung when there's no project env to carry the tool.

3. **Route: ephemeral vs. permanent.** Judge by a **blend of lifetime, benefit, and frequency** — how long you'll need it, how much it helps, how often it recurs. **Default to ephemeral.** A one-off or short-lived need stays ephemeral; a tool that is clearly recurring, broadly useful, and long-lived is a *permanent* candidate.

   - **Ephemeral — act on it yourself.** Use the pinned registry (the `nixpkgs#` registry is pinned to the system `nixpkgs`, currently `26.11` — do not add a flake ref or version):
     - `nix run nixpkgs#<pkg> -- <args>` for a single one-off invocation.
     - `nix shell nixpkgs#<pkg>` to drop the tool onto `PATH` for several commands in this session.
     - **Never** `nix profile install` or `nix-env -i` — those imperatively mutate the user profile and are the anti-pattern in Nix clothing.
   - **Permanent — always *propose*, never install.** When a tool crosses into permanent territory, open the propose-a-config-edit path below. Meanwhile, **proceed ephemerally** so you're never blocked waiting on the proposal.

4. **Not in nixpkgs.** If discovery turns up nothing, the tool isn't packaged. Don't fall back to an imperative install — **actively propose vendoring** it into the repo, invoking the `bump-nix-package` skill, which owns the mechanics of authoring/adding the derivation. Routing here is in scope; the derivation authoring is the skill's job.

## The propose-a-config-edit path (permanent tools)

When rung 3 or 4 marks a tool as permanent, you *propose* a Nix config edit — you never apply it as a side effect of the current task.

- **Scope-routing — where the package goes:**
  - **Default: user scope** — add to `home.packages` in `nix/home/default.nix`. This is the right home for almost every CLI tool.
  - **System scope** — `environment.systemPackages` — only when the tool must live **outside the user session** (needed by root, by a systemd unit, at boot, or by all users). State the tipping test explicitly when you choose it: *this tool has to exist outside my interactive user session, so user scope can't reach it.*
  - **Vendored** — `nix/pkgs/*.nix` — when the tool isn't in nixpkgs (rung 4), via `bump-nix-package`.

- **Placement — where in the tree:** put the edit next to the **closest existing sibling** — the least-conditional, least-host-specific location that is still correct. If no correct shared spot exists, you may create a new `common` module rather than forcing it into a host- or profile-specific file.

- **Artifact — how you propose it:** a **PR carrying the edit on its own dedicated branch**. Never fold the config edit into the branch of the task that surfaced the need — it gets its own branch and its own PR, reviewed on its own merits. Proceed ephemerally on your original task while the PR is pending.

## opencode hard-stops (enforcement layer)

Guidance is the baseline, but on opencode the workflow is also **enforced**, so the anti-pattern is blocked, not just discouraged. Two layers:

1. **Primary — a `tool.execute.before` plugin** that inspects the bash command string and blocks matches by regex before execution.
2. **Backstop — `permission.bash` deny rules** for the same commands, in case the plugin is bypassed.

(`PATH`-shadow shims — replacing `npm`/`pip` on `PATH` with rejecting stubs — are **out of scope**; the two layers above are the whole mechanism.)

**Block** (imperative, un-reproducible installs):

- `npm i -g` / `npm install -g` (global npm)
- bare `pip install` and `pipx install`
- `cargo install`
- `go install`
- `curl … | sh` (and equivalent pipe-to-shell)

**Allow** (legitimate, reproducible, or project-local):

- `npm ci`
- local `npm install` (no `-g`, inside a project)
- `pip install -r <file>` **only** in an explicit command-string venv form (e.g. an explicit venv `pip` path or activated-venv invocation). Detecting a venv via environment variables was considered and **dropped as unreliable** — the allow-list keys on the visible command string, not on ambient env.

Authoring the plugin, the deny rules, and the Nix wiring is the spec's **implementation** and is tracked separately; this file states what that enforcement must commit to.
