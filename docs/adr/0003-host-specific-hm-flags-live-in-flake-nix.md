# Host-specific Home Manager flags live in flake.nix

`enableVscodeSandbox` and `isWork` are Home Manager options declared under
`dandyrow.*`. They vary per host: the work laptop enables the sandbox, the
personal machine does not.

NixOS modules cannot set Home Manager options. The two module systems are
separate, so moving these flags into per-host NixOS configuration is not
possible. On the standalone path, `osConfig` is null by definition, so there
is no NixOS configuration to read from either. The flake is the only layer
that handles both activation paths (`mkSystem` for NixOS, `mkHome` for
standalone), so the flags must be set there.

## Considered Options

**Setting the flags from per-host NixOS modules** was rejected. NixOS modules
have no access to Home Manager option declarations. Threading the flags through
`specialArgs` or `extraSpecialArgs` adds indirection without removing the
flake's role.

**Reading the flags from `osConfig` inside Home Manager** was rejected for the
standalone path. `osConfig` is always null when Home Manager runs outside
NixOS. The standalone path would need a second source of truth or fall back to
a default that defeats the purpose.

**Declaring per-host Home Manager configurations in the flake** was rejected.
The flake already wires one `home-manager.users.<name>` per NixOS host and one
`homeConfigurations.<name>` for standalone. Host-specific outputs would mean
three copies of the same user instead of two, with the flags further from where
they are consumed.
