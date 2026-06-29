---
name: bump-nix-package
description: Use when bumping the version of a vendored package under nix/pkgs/ or vendoring a new package into the repo
---

# Vendored Nix Package Version Bumps

## When this applies

- Bumping the `version` of an existing file under `nix/pkgs/`
- Updating its `hash` / `src.hash` after a version change
- Adding a new vendored package and wiring it into the overlay in `flake.nix`
- Removing a vendored override because nixpkgs has caught up

It does **not** apply to nixpkgs-managed packages — those are bumped by
updating `nixpkgs` in `flake.nix` and running `nix flake update`.

## Recipe (run in order)

1. **Worktree.** `./scripts/agent-start.sh feat/<pkg>-<version>` from the
   main checkout. All work happens in the resulting worktree.

2. **Prefetch the new source.**
   ```bash
   nix-prefetch-url --type sha256 "<URL with new version>"
   nix hash convert --hash-algo sha256 --to sri <hash-from-step-above>
   ```
   The SRI value (`sha256-...=`) is what goes in the derivation.

3. **Choose: vendor a fresh copy, or `overrideAttrs`?**
   - **Default — vendor a fresh copy.** Copy the current upstream
     `package.nix` into `nix/pkgs/<name>.nix` verbatim, then change
     `version` and `hash`. Add a 1–2 line header comment marking the file
     as a tracking override and naming the version at which nixpkgs can
     reclaim it. Example:
     ```nix
     # Local override of nixpkgs' <name> to track a newer upstream than
     # nixos-unstable currently ships. Delete this file (and the overlay
     # entry in flake.nix) once nixpkgs catches up to this version or
     # newer.
     ```
   - **`overrideAttrs` only if** the change is purely `version` + `src` and
     the upstream derivation is small and stable. Be aware that when
     upstream uses `mkDerivation (finalAttrs: { ... src.url = "...v${finalAttrs.version}..."; })`,
     overriding `version` alone does **not** change the URL because `src`
     is already bound to the original `finalAttrs.version`. You must
     override `src` with the full URL inlined, or use the vendor path.

4. **Wire into the overlay.** In `flake.nix`, add a line to the existing
   overlay attribute:
   ```nix
   <name> = final.callPackage ./nix/pkgs/<name>.nix { };
   ```
   For unfree packages, also ensure the package name is in
   `allowUnfreePredicate`.

5. **Stage immediately.** `git add nix/pkgs/<name>.nix flake.nix`. The
   flake uses the git tree as its source of truth — `nix eval` and
   `nix build` cannot see untracked files. Skipping this step produces a
   confusing `error: path '...' does not exist` from an otherwise valid
   derivation.

6. **Evaluate all hosts.** Read `flake.nix` to discover the current set of
   `nixosConfigurations`. Evaluate each — WSL requires `--impure` because
   its configuration references `/etc/nixos/corp.pem` via `builtins.pathExists`:
   ```bash
   nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
   nix eval .#nixosConfigurations.WSL.config.system.build.toplevel.drvPath --impure
   ```

7. **Build the package itself, not just the host system.**
   ```bash
   nix build --no-link --print-out-paths .#nixosConfigurations.$HOST.pkgs.<name>
   ```
   This isolates the failure surface to the new derivation. Build
   failures here typically mean: a new hash mismatch, a new shared
   library that `autoPatchelfHook` cannot find (see "Common failure
   modes" below), or a `versionCheckHook` mismatch.

8. **Behavioural smoke test.** Run the built binary directly out of the
   nix store and confirm it reports the new version. For most CLIs:
   ```bash
   /nix/store/...-<name>-<version>/bin/<mainProgram> --version
   ```

9. **Commit.** Use gitmoji + conventional commits format. The commit body should include:
   - One sentence on why nixpkgs isn't sufficient (current version vs target version).
   - Any non-version-non-hash changes (e.g. additions to `autoPatchelfIgnoreMissingDeps`) with one-sentence justifications.
   - The verification checks that passed.
   - A "delete this when nixpkgs catches up" line so future-you knows the override is disposable.

10. **Push + open PR in the same turn.** Pushing a feature branch and
    opening a PR do not require explicit user approval:
    ```bash
    git push -u origin feat/<pkg>-<version>
    gh pr create --base main --fill
    ```

## Common failure modes

### `autoPatchelfHook` reports new missing shared libraries

When the package ships native Node prebuilds, new upstream releases
sometimes add prebuilds for variants that aren't usable on glibc NixOS
(e.g. `linuxmusl-x64/keytar.node` wanting `libc.musl-x86_64.so.1`). The
*usable* prebuild for your platform is what actually loads at runtime;
the others are dead weight. Add the missing lib to
`autoPatchelfIgnoreMissingDeps` rather than trying to satisfy it. Match
the comment style of the existing entries — explain *which* unused
prebuild needs it and *why* the glibc variant is what loads.

If a missing lib is wanted by the prebuild that *does* load on your
platform, that's a real dependency — add the package providing the lib
to `buildInputs` instead of ignoring it.

### `versionCheckHook` failure

If `nix build` succeeds the patchelf phase but fails at install-check
with a version mismatch, double-check the new tarball is actually the
one you intended (`nix-prefetch-url` of the URL embedded in the
derivation should match the SRI hash). The `finalAttrs.version` /
`src.url` trap from step 3 above is the usual culprit when using
`overrideAttrs`.

### "Path does not exist" on `nix eval`

The new `.nix` file isn't staged. Run `git add <path>` (explicit path,
never `-A` or `.`) and retry. See step 5.

### `warning: Git tree '...' is dirty`

Harmless. The flake reads the worktree's git index; uncommitted
modifications produce this warning but evaluation still uses the
working-tree contents. Distinct from the "path does not exist" error,
which means the file is untracked entirely.

## When `nixos-rebuild switch` is needed

Runtime behaviour beyond `--version` cannot be agent-verified end-to-end.
After the PR merges, propose this to the user but do not run it without
explicit approval:

```bash
sudo nixos-rebuild switch --flake .#$HOST $( [[ "$HOST" == "WSL" ]] && echo --impure )
<mainProgram> --version  # confirm it picks up the new version
```

## When nixpkgs catches up

Delete the file under `nix/pkgs/<name>.nix` and the matching line from
the overlay in `flake.nix`. Verify with the same eval + build checks
that the nixpkgs-provided package is now at or above the version we
were tracking, then commit and PR. The "delete this when nixpkgs
catches up" line in the original commit message helps you find these.
