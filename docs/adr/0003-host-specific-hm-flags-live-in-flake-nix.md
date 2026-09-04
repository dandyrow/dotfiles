# Host-specific Home Manager flags live in flake.nix

The `enableVscodeSandbox` and `isWork` flags are Home Manager options declared
under `dandyrow.*` in `nix/home/core/work-identity.nix` and
`nix/home/core/vscode-sandbox.nix`. They vary per host (e.g. work laptop
enables the sandbox, personal machine does not). Moving them into per-host
NixOS configuration is not possible because the NixOS and Home Manager module
systems are separate — NixOS modules cannot set Home Manager options. On the
standalone Home Manager path, `osConfig` is null by definition, so there is no
NixOS configuration to read from either way. The only layer that touches both
activation paths is the flake's Home Manager wiring (`mkSystem` for NixOS,
`mkHome` for standalone), so the flags must be set there.

## Considered Options

**Setting the flags from per-host NixOS modules** was rejected. The two module
systems are disjoint — a NixOS module has no type-level access to Home Manager
option declarations. The flags would need to be threaded through `specialArgs`
or `extraSpecialArgs`, which duplicates the same coupling the flake already
solves and adds an indirection without removing the flake's role.

**Reading the flags from `osConfig` inside Home Manager** was rejected for the
standalone path. When Home Manager runs outside NixOS, `osConfig` is `null` by
definition. Gating behaviour on a value that is always null in one of the two
supported paths means the standalone path cannot function — it would either
need a second source of truth or silently fall back to a default that defeats
the purpose of the flag.

**Declaring per-host Home Manager configurations in the flake** was rejected.
The flake already wires one `home-manager.users.<name>` per NixOS host and one
`homeConfigurations.<name>` for standalone. Duplicating that into
host-specific HM flake outputs would mean maintaining three copies of the same
user instead of two, with the flags moving further from where they are
consumed.
