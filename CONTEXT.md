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

## Related

- Tests: `nix/tests/has-desktop.nix`, exposed as `checks.<system>.has-desktop`.
