# CONTEXT.md

Glossary of domain terms used across this NixOS + Home Manager configuration.

## Glossary

### hasDesktop

Exposed as the Home Manager option `dandyrow.hasDesktop` (`nix/home/desktop.nix`).

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
list in `nix/home/dotfiles.nix`. Add a name to stow a new tool. Tools that don't
fit the convention (gnupg, copilot, tmux, the work gitconfig) are co-located
exceptions in the same module.

A concern distinct from the **dotfiles clone** — linking assumes the clone
already exists.

### dotfiles clone

Ensuring the `~/.dotfiles` clone of the dotfiles repo exists before linking.
A single command definition (`nix/lib/clone-dotfiles.nix`) rendered through two
activation adapters: root system activation on NixOS
(`nix/modules/common/clone-dotfiles.nix`) and user Home Manager activation off
NixOS (`nix/home/clone-dotfiles.nix`). See `docs/adr/0001-dotfiles-clone-two-adapters.md`.

## Related

- Tests: `nix/tests/has-desktop.nix`, exposed as `checks.<system>.has-desktop`.
- Tests: `nix/tests/clone-dotfiles.nix`, exposed as `checks.<system>.clone-dotfiles`.
