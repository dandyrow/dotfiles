# Dotfiles clone is one definition behind two activation adapters

The dotfiles repo must be cloned to `~/.dotfiles` before Home Manager stows
symlinks out of it, in two different contexts: a NixOS host (so a single
`nixos-anywhere` command installs with zero interaction) and standalone Home
Manager off NixOS. We keep the `git clone` command as a **single definition**
(`nix/lib/clone-dotfiles.nix`) rendered through **two thin adapters** — a root
`system.activationScripts` entry on NixOS (`nix/modules/common/clone-dotfiles.nix`,
with `chown` and the CA bundle for the install-time proxy) and a user
`home.activation` entry off NixOS (`nix/home/clone-dotfiles.nix`).

## Considered Options

A single *runtime* clone on the Home Manager side (dropping the NixOS
system-activation clone, letting `home-manager-dandyrow.service` clone on first
boot before `linkGeneration`) was rejected. On NixOS that HM service runs **as
the user at `multi-user.target`**, whereas the current NixOS clone runs **as root
during early system activation** with a `chown` back to the user. Moving the
clone there would change privilege (root→user) and boot timing and would rely on
the network being up at `multi-user.target` — a real risk to the zero-interaction
`nixos-anywhere` guarantee. Two adapters over one definition keep that guarantee
intact while removing the duplication that mattered: the clone command itself.
