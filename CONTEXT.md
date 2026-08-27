# CONTEXT.md

Glossary of domain terms used across this NixOS + Home Manager configuration.

## Glossary

### hasDesktop

Exposed as the Home Manager option `dandyrow.hasDesktop`, declared by the
option module `nix/home/desktop.nix` (distinct from the `desktop/` directory of
consumer modules).

Whether the machine runs a graphical desktop environment. Consumers gate
desktop-only configuration on it: kitty, GNOME extensions, Firefox, GTK theming,
dconf settings, and MIME app associations.

**Derivation.** Defaults to the host NixOS configuration's GNOME state
(`osConfig != null && (osConfig.gnome.enable or false)`). Off NixOS, Home Manager
supplies `osConfig = null`, so the default is `false`. It is a plain `mkOption`,
not `mkEnableOption`, so a standalone non-NixOS desktop can override it to `true`.

**Why the abstract name.** `hasDesktop` was chosen over `gnomeEnabled` on
purpose. A second desktop environment / window manager is anticipated. The
interface must not leak the GNOME signal, so that when a second DE lands the
derivation grows to a disjunction in one file and no consumer changes.

**Namespacing.** Lives under the personal `dandyrow` namespace rather than
top-level, avoiding collision with upstream Home Manager options.

**Scope.** Home Manager only. The NixOS side already expresses the same fact as
`gnome.enable`, so a system-side twin would have no readers today. Promoting it
to system scope is the cheap future move if a system consumer appears.

**Avoid these synonyms:** `gnomeEnabled`, `isDesktop`, `desktopMode`.

### dotfile linking

Stowing a tool's checked-in config out of the `~/.dotfiles` clone via
`mkOutOfStoreSymlink`. The dominant case is the **config-link convention**:
`~/.config/NAME` → `~/.dotfiles/NAME/.config/NAME`, driven by the `configLinks`
list in the dotfile-linking home module. Add a name to stow a new tool. Tools
that don't fit the convention (gnupg, copilot, tmux, the work gitconfig) are
co-located exceptions in the same module.

A concern distinct from the **dotfiles clone** — linking assumes the clone
already exists.

### dotfiles clone

Ensuring the `~/.dotfiles` clone of the dotfiles repo exists before linking.
A single command definition (`nix/lib/clone-dotfiles.nix`) rendered through two
activation adapters: root system activation on NixOS and user Home Manager
activation off NixOS. See `docs/adr/0001-dotfiles-clone-two-adapters.md`.

### nvim tools

The definition of which LSP/formatter/linter/dap binaries Neovim needs, in
`nvim/.config/nvim/lua/config/tools.json`. The same JSON drives two install
paths: on NixOS/Home Manager the nixpkgs path resolves every entry that is not
`masonOnly` to a package (`nix/lib/nvim-tools.nix`, via the single
`nvimToolPackages` function); off NixOS, Mason installs them at runtime.

The `nixOnly` flag marks tools Mason cannot provide (nixd, nixfmt), so they
must come from nixpkgs. The nixpkgs path already includes them because they are
not `masonOnly`; the flag is read only by the Mason side, not the nixpkgs one.

### primary user

Exposed as the option `dandyrow.primaryUser`, declared once per module system —
once for NixOS, once for Home Manager.

The login name of the single human this machine belongs to — the account with a
password, a home directory, a shell, group memberships and a Home Manager
generation. Singular by design: this names *the* primary user, not a set of
users.

**Derivation.** It is not derived; it is declared, with the same default on both
sides. Deriving it by filtering the configured users for the normal one is
impossible, not merely awkward — see
`docs/adr/0002-primary-user-declared-once.md`. The NixOS declaration is
authoritative on NixOS, where Home Manager takes the user's identity from the
NixOS account and the Home Manager declaration is inert. Off NixOS the Home
Manager declaration stands alone. A plain `str` with a default, so a single host
overrides it as ordinary configuration.

**Namespacing.** Lives under the personal `dandyrow` namespace on both sides,
avoiding collision with upstream options — as `hasDesktop` does.

**The password-hash file names the role, not the occupant** —
`/etc/secrets/primary-user-password`, injected at install time. It does not
follow the option, so a rename never moves the secret and the installer needs no
knowledge of the name.

**Not the primary user**, despite sharing the string: the GitHub account in the
dotfiles clone URL, the `homeConfigurations` output names, the flake
description, the comment fields inside SSH public keys, and the clone-dotfiles
test fixtures.

**Avoid these synonyms:** `mainUser`, `owner`, `theUser`.
