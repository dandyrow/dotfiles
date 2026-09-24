# PipeWire / Printing "base" classification

`nix/modules/base/pipewire.nix` and `nix/modules/base/printing.nix` live
under `base/` despite being imported only by `desktop/gnome.nix`. This is
intentional, not a classification mismatch to resolve.

## Why this is out of scope

These files define *options* — `pipewire.enable` and `printing.enable` —
gated behind `mkEnableOption`. They are reusable service definitions, not
desktop-specific implementations. The `base/` location reflects their role:
any environment (GNOME, KDE, a headless box that prints) could enable them.

Moving them to `desktop/` would narrow their classification to "desktop-only
services," which is false. PipeWire is used for pro-audio headless setups;
CUPS runs on servers.

`base/default.nix` only imports modules needed unconditionally. These modules
are conditional on their `.enable` flags, so importing them from
`base/default.nix` would also be wrong — they'd be loaded everywhere
regardless of whether anything enables them.

The current layout is correct: optional service definitions live in `base/`,
and consumers (`gnome.nix`, or a future KDE module) import them where needed.

## Prior requests

- #156: "refactor(nixos): correct the pipewire/printing base classification"
