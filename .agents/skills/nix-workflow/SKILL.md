---
name: nix-workflow
description: Use when editing any .nix files in this repo, or when another skill needs nix verification steps
---

## Visibility

The flake's **visibility** is the git index — only staged files are visible to `nix eval`, `nix build`, and `nix flake check`. Stage new `.nix` files immediately; untracked files produce `error: path '...' does not exist`.

**If changing flake inputs, update the lockfile:**

```bash
nix flake update
```

## Verification

List `./nix/hosts/` to discover the current set of hosts. Evaluate each before claiming a change is correct.

WSL requires `--impure` because its configuration references `/etc/nixos/corp.pem` via `builtins.pathExists`:

```bash
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.WSL.config.system.build.toplevel.drvPath --impure
```

For changed packages, also build the derivation directly to isolate failures:

```bash
nix build --no-link --print-out-paths .#nixosConfigurations.<host>.pkgs.<name>
```

## Runtime behaviour

Behavioural changes that only manifest after `nixos-rebuild switch` cannot be agent-verified end-to-end. State this explicitly in the PR and propose the post-switch commands the user should run. Never claim "this fixes X" on the strength of a successful eval alone.

## Style

Prefer hoisting repeated literals (versions, hashes, URLs) into `let` bindings or attributes so they update in one place.
