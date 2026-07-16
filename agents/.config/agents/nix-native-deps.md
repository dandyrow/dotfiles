# Nix-native dependency workflow

Machine-global guidance for every AI agent operating on this NixOS machine. When you need a system or CLI tool, run it ephemerally through Nix or propose adding it to the Nix config. Never satisfy a tool-need with an imperative, out-of-Nix install the system can't reproduce.

## Scope

This governs **system and CLI tools**, executables you'd reach for on the command line (formatters, linters, language servers, CLIs, interpreters needed as ambient tools).

It does **not** govern **project-local language dependencies**, packages a project declares for itself (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`) and installs into its own tree. The line: does the tool belong to *the machine/your session* (on the ladder) or to *the project you're working in* (off the ladder)?

## The dependency decision ladder

**Trigger:** an unmet tool-need. You reach for a system/CLI tool that isn't on `PATH`. This includes any imperative install that lands outside Nix (see the *denylist* below). Instead of installing imperatively stop and walk the ladder.

1. **Discover.** Find which Nix package provides the tool with `nix-locate <binary>` (e.g. `nix-locate bin/rg`). This maps a missing command to its `nixpkgs` attribute. If discovery turns up nothing the tool isn't packaged: don't fall back to an imperative install, it becomes a **vendoring proposal** on the proposal path below, which owns the not-in-nixpkgs case.

2. **Prefer a project environment.** If the project defines its own environment, use it rather than reaching to the machine: `nix develop` for a flake devShell, or `nix-shell shell.nix` for a legacy shell. (Note: `direnv` is not available here, so environments are entered explicitly, not auto-loaded.) Only climb past this rung when there's no project env to carry the tool.

3. **Route: ephemeral vs. permanent.** **Default to ephemeral.** A one-off or short-lived need stays ephemeral; a tool that is clearly recurring, broadly useful, and long-lived is a *permanent* candidate.

   - **Ephemeral, act on it yourself.** Use the pinned version of nixpkgs from the system's flake:
     - `nix run nixpkgs#<pkg> -- <args>` for a single one-off invocation.
     - `nix shell nixpkgs#<pkg>` to drop the tool onto `PATH` for several commands in this session.
     - **Never** `nix profile install` or `nix-env -i` (on the *denylist*).
   - **Permanent, always *propose*, never install.** When a tool crosses into permanent territory, open the proposal path below. Meanwhile, **proceed ephemerally** so you're never blocked waiting on the proposal.

## The proposal path (permanent tools)

When rung 1 or 3 marks a tool as permanent, you *propose* a Nix config edit. You never *apply* it as a side effect of the current task.

Every proposal targets the machine's Nix config at **`~/.dotfiles`**. The paths below (`nix/home/default.nix`, `nix/pkgs/`) are relative to it. What *proposing* means depends on where you're working:

- **Already inside `~/.dotfiles`:** open the edit as a **PR on its own dedicated branch**, never folded into the branch of the task that surfaced the need. The branching and commit mechanics are governed by `~/.dotfiles`'s own `AGENTS.md`, which loads when you're in that repo.
- **In any other repo:** do **not** reach into `~/.dotfiles` to open a PR as a side effect of unrelated work. Instead **surface the proposal** by naming the tool, the scope you'd choose, and the exact target path, so it can be carried into a `~/.dotfiles` session.

- **Scope-routing, where the package goes:**
  - **Default: user scope.** Add to `home.packages` in `nix/home/default.nix`. This is the right home for almost every CLI tool.
  - **System scope** (`environment.systemPackages`), only when the tool must live **outside the user session** (needed by root, by a systemd unit, at boot, or by all users). State the reason for system scope explicitly when you choose it: *this tool has to exist outside my interactive user session, so user scope can't reach it.*
  - **Vendored** (`nix/pkgs/*.nix`), when the tool isn't in nixpkgs (rung 1), via `bump-nix-package` skill.

- **Placement, where in the tree:** put the edit next to the **closest existing sibling**, the least-conditional, least-host-specific location that is still correct. If no correct shared spot exists, you may create a new `common` module rather than forcing it into a host or profile specific file.

## Denylist and allowlist

These are the imperative, un-reproducible installs the ladder exists to prevent, and the reproducible or project-local ones it leaves alone.

**Denylist** (imperative, un-reproducible installs):

- `npm i -g` / `npm install -g` (global npm)
- bare `pip install` and `pipx install`
- `cargo install`
- `go install`
- `curl ... | sh` (and equivalent pipe-to-shell)
- `nix profile install` / `nix-env -i` (imperative profile mutation, the anti-pattern in Nix clothing)

**Allowlist** (reproducible, or project-local):

- `npm ci`
- local `npm install` (no `-g`, inside a project)
- `pip install -r <file>` **only** in an explicit command-string venv form (e.g. an explicit venv `pip` path or activated-venv invocation), keyed on the visible command string, not on ambient env.
