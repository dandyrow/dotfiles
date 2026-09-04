# Pipewire and printing stay as opt-in base modules

`pipewire.nix` and `printing.nix` live in `nix/modules/base/` and declare
opt-in enable options (`pipewire.enable`, `printing.enable`). GNOME's
`gnome.nix` imports them and sets both to `true`. The modules are genuinely
opt-in: a second desktop environment would import them the same way rather than
re-declaring the same services inline.

## Considered Options

Inlining PipeWire and CUPS configuration directly into `gnome.nix` was
rejected. It would duplicate the services, RTKit, cups-pdf, polkit, and the
system-config-printer disable that the base modules already provide. It would
also close the seam: non-GNOME consumers could no longer reuse the modules
without extracting them again. `gnome.nix` imports and enables them, which is
how desktop environments should compose with base modules.
