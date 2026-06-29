---
name: nix-workflow
description: Use when editing any .nix files or making NixOS configuration changes in this repo
---

# Nix Workflow

## Before making changes

**Stage new `.nix` files immediately after writing them.** The flake uses the git tree as its source of truth — `nix eval`, `nix build`, and `nix flake check` cannot see untracked files. A new file produces `error: path '...' does not exist` until staged:

```bash
git add <path>  # explicit path only, never -A or .
```

**If changing flake inputs, update the lockfile:**

```bash
nix flake update
```

## Verification

Read `flake.nix` to discover the current set of `nixosConfigurations`. Evaluate each before claiming a change is correct.

WSL requires `--impure` because its configuration references `/etc/nixos/corp.pem` via `builtins.pathExists`:

```bash
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.WSL.config.system.build.toplevel.drvPath --impure
```

For changed packages, also build the derivation directly to isolate failures:

```bash
nix build --no-link .#nixosConfigurations.<host>.pkgs.<name>
```

## Runtime behaviour

Behavioural changes that only manifest after `nixos-rebuild switch` cannot be agent-verified end-to-end. State this explicitly in the PR and propose the post-switch commands the user should run. Never claim "this fixes X" on the strength of a successful eval alone.

## Style

Prefer hoisting repeated literals (versions, hashes, URLs) into `let` bindings or attributes so they update in one place.
