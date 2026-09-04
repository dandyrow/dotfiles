# Pipewire and printing stay as opt-in base modules

`pipewire.nix` and `printing.nix` live in `nix/modules/base/` and declare
opt-in enable options (`pipewire.enable`, `printing.enable`). GNOME's
`gnome.nix` imports them and sets both to `true`. The modules are genuinely
opt-in infrastructure: a second desktop environment (e.g. KDE) would import
them the same way rather than re-declaring the same services inline.

## Considered Options

Inlining PipeWire and CUPS configuration directly into `gnome.nix` was
rejected. It would duplicate the services, RTKit, cups-pdf, polkit, and the
system-config-printer disable that the base modules already provide, and it
would close the seam — non-GNOME consumers could no longer reuse the modules
without extracting them again. The import-then-enable pattern in `gnome.nix`
is the correct composition mechanism for base modules with desktop
environments.
