---
name: bump-nix-package
description: Use when bumping the version of a vendored package under nix/pkgs/, vendoring a new package into the repo, or removing a vendored override once nixpkgs has caught up
---

# Vendored Nix Package Version Bumps

**REQUIRED SUB-SKILL:** Use `nix-workflow` — it covers **visibility** (staging), host evaluation, and build verification.

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
     `version` and `hash`. Add a 1–2 line tracking header comment. Example:
     ```nix
     # Local override of nixpkgs' <name> to track a newer upstream than
     # nixos-unstable currently ships. Delete this file (and the overlay
     # entry in flake.nix) once nixpkgs catches up to this version or
     # newer.
     ```
   - **`overrideAttrs` only if** the change is purely `version` + `src` and
     the upstream derivation is small and stable. Be aware of **binding**: when
     upstream uses `mkDerivation (finalAttrs: { ... src.url = "...v${finalAttrs.version}..."; })`,
     `src` is bound to the original `finalAttrs.version` at definition time. Override `src` with
     the full URL inlined, or use the vendor path.

4. **Wire into the overlay.** In `flake.nix`, add a line to the existing
   overlay attribute:
   ```nix
   <name> = final.callPackage ./nix/pkgs/<name>.nix { };
   ```
   For unfree packages, also ensure the package name is in
   `allowUnfreePredicate`.

5. **Build the package itself, not just the host system.**
   ```bash
   nix build --no-link --print-out-paths .#nixosConfigurations.$HOST.pkgs.<name>
   ```
   This isolates the failure surface to the new derivation. Build
   failures here typically mean: a new hash mismatch, a new shared
   library that `autoPatchelfHook` cannot find (see "Common failure
   modes" below), or a `versionCheckHook` mismatch.

6. **Behavioural smoke test.** Run the built binary directly out of the
   nix store and confirm it reports the new version. For most CLIs:
   ```bash
   /nix/store/...-<name>-<version>/bin/<mainProgram> --version
   ```

7. **Commit.** The commit body should include:
   - One sentence on why nixpkgs isn't sufficient (current version vs target version).
   - Any non-version-non-hash changes (e.g. additions to `autoPatchelfIgnoreMissingDeps`) with one-sentence justifications.
   - The verification checks that passed.
   - A "delete this when nixpkgs catches up" line so future-you knows the override is disposable.

8. **Push + open PR in the same turn.**
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
derivation should match the SRI hash). The **binding** trap from step 3
is the usual culprit when using `overrideAttrs`.

### `warning: Git tree '...' is dirty`

Harmless. The flake reads the worktree's git index; uncommitted
modifications produce this warning but evaluation still uses the
working-tree contents. Distinct from a **visibility** error (`error: path
'...' does not exist`), which means the file is untracked entirely — see
`nix-workflow`.

## When `nixos-rebuild switch` is needed

Runtime behaviour beyond `--version` cannot be agent-verified end-to-end.
After the PR merges, propose this to the user but do not run it without
explicit approval:

```bash
sudo nixos-rebuild switch --flake .#$HOST $( [[ "$HOST" == "WSL" ]] && echo --impure )
<mainProgram> --version  # confirm it picks up the new version
```

## Branch: nixpkgs has caught up

Delete `nix/pkgs/<name>.nix` and the matching line from the overlay in
`flake.nix`. Verify with the eval + build checks from `nix-workflow` that
the nixpkgs-provided package is now at or above the version being tracked,
then commit and PR. The "delete this when nixpkgs catches up" line in the
original commit message helps you find these.
