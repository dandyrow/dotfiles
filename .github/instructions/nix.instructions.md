---
applyTo: "**/*.nix,flake.nix,flake.lock,nix/**"
---

# Nix-scoped Guidance (applies only to Nix files)

## Goals
- Keep changes **reproducible** and **portable** across machines.
- Minimise churn: prefer small, focused diffs.
- Preserve the repo's structure: dotfiles live alongside Nix, but Nix logic should remain primarily under `nix/`.

## Rules (do these every time)
- Prefer editing within `nix/` for system and Home Manager config; avoid scattering Nix logic into dotfile areas unless the repo already does so.
- Treat `flake.nix` and `flake.lock` as the authoritative entrypoints for Nix systems.
- Avoid machine-specific absolute paths and environment-dependent behaviours.
- If you add or change packages/tools, prefer doing so through Nix definitions rather than ad-hoc shell scripts.
- If you change outputs or inputs, consider whether `flake.lock` needs updating and keep it consistent with `flake.nix`.

## Validation (run when practical)
- Run `nix flake check` if available and not prohibitively slow for the change.
- If the change impacts a particular host/home configuration, run the relevant build/switch command (if documented in the repo).
- If formatting tools are used in this repo, apply them consistently.

## Boundaries
- Never introduce secrets into Nix files.
- Don't restructure modules or rename large paths unless explicitly requested.
- When uncertain, follow existing patterns in `nix/` and ask a clarifying question.
