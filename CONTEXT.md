# CONTEXT.md

Glossary of domain terms used across this NixOS + Home Manager configuration.

## Glossary

### isStandalone

Exposed as the Home Manager option `dandyrow.isStandalone`, declared by the
option module `nix/home/facts.nix` alongside `hasDesktop` and `primaryUser`.

Whether Home Manager runs standalone, outside the NixOS module system with
`osConfig = null`, and must provide for itself what NixOS would otherwise
supply.

**Derivation.** Defaults to `osConfig == null`: Home Manager always supplies the
`osConfig` argument, null off NixOS. It is a plain `mkOption`, not
`mkEnableOption`, so a hypothetical future standalone run could override it.

**Why the abstract name.** `isStandalone` was chosen over a NixOS-flavoured
alias. The interface must not leak `osConfig` into the name, for the same reason
`hasDesktop` avoids a GNOME-specific name: changing how the fact is decided in
future stays confined to this one derivation.

**Relationship to hasDesktop and primaryUser.** `hasDesktop` derives from
`isStandalone` (standalone resolves to `false`). `primaryUser` is deemed
comparable to a declaration: though it feeds `home.username` and
`home.homeDirectory`, those always equal the primary user, so all three live
together in `facts.nix`. The username frames are applied by the consuming
home module, gated on `isStandalone`.

**Namespacing.** Lives under the personal `dandyrow` namespace, as `hasDesktop`
and `primaryUser` do, avoiding collision with upstream Home Manager options.

**Scope.** Home Manager only. NixOS has no "standalone" concept; a NixOS run
always has an `osConfig`, so no system-side twin exists.

**Avoid these synonyms:** `onNixOS`, `isStandaloneHM`, `osConfigNull`.

### hasDesktop

Exposed as the Home Manager option `dandyrow.hasDesktop`, declared by the
option module `nix/home/facts.nix` (distinct from the `desktop/` directory of
consumer modules).

Whether the machine runs a graphical desktop environment. Consumers gate
desktop-only configuration on it.

**Derivation.** Defaults to the host NixOS configuration's GNOME state when Home
Manager runs as a NixOS module; standalone Home Manager derives `false` and may
override it to `true`. It is a plain `mkOption`, not `mkEnableOption`, so a
standalone non-NixOS desktop can override it to `true`.

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
that don't fit the convention are co-located exceptions in the same module.

A concern distinct from the **dotfiles clone**: linking assumes the clone
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

The `nixOnly` flag marks tools Mason cannot provide, so they must come from
nixpkgs. The nixpkgs path already includes them because they are not
`masonOnly`; the flag is read only by the Mason side, not the nixpkgs one.

### primary user

Exposed as the option `dandyrow.primaryUser`, declared once per module system,
once for NixOS and once for Home Manager.

The login name of the single human this machine belongs to: the account with a
password, a home directory, a shell, group memberships and a Home Manager
generation. Singular by design. This names *the* primary user, not a set of
users.

**Derivation.** It is not derived; it is declared, with the same default on both
sides. Deriving it by filtering the configured users for the normal one is
impossible, not merely awkward. See
`docs/adr/0002-primary-user-declared-once.md`. The NixOS declaration is
authoritative on NixOS, where Home Manager takes the user's identity from the
NixOS account and the Home Manager declaration is inert. Off NixOS the Home
Manager declaration stands alone. A plain `str` with a default, so a single host
overrides it as ordinary configuration.

**Namespacing.** Lives under the personal `dandyrow` namespace on both sides,
avoiding collision with upstream options, as `hasDesktop` does.

**The password-hash file names the role, not the occupant**:
`/etc/secrets/primary-user-password`, injected at install time. It does not
follow the option, so a rename never moves the secret and the installer needs no
knowledge of the name.

**Not the primary user**, despite sharing the string: the GitHub account in the
dotfiles clone URL, the `homeConfigurations` output names, the flake
description, the comment fields inside SSH public keys, and the clone-dotfiles
test fixtures.

**Avoid these synonyms:** `mainUser`, `owner`, `theUser`.

### agent

A coding-agent process (opencode, copilot, Claude Code, …) running inside a
herdr pane. Herdr detects its lifecycle state and rolls it up to the workspace
as one of `idle`, `working`, `blocked`, `done`. This is why tmux is gone. Tmux
sees only an undifferentiated process; herdr sees whether it needs you.

**Session identity.** An official integration, Nix-linked from the herdr source
rather than `herdr integration install`, reports a native session reference so
herdr can resume the conversation after a server restart. Resurrect and
continuum never did that. This is distinct from a herdr **session** and from
tmux sessions.

**State and lifecycle authority.** The screen manifest supplies state;
integration hooks and plugins supply lifecycle. Not every pane holds an agent.
A pane is the terminal; an agent is an identified process inside it.

**Avoid these synonyms:** pane, process, workspace.

### session

Herdr's top-level container. Its server owns the panes and the terminals people
attach to. This configuration runs exactly one, the default, and all projects
live inside it as **workspaces**.

**Not the old tmux session.** The named, parallel tmux session, one per project,
went away. Herdr maps that need to **workspaces** inside the single session
instead. The `HERDR_ENV` variable the server injects into panes doubles as the
"inside herdr" marker the old `$TMUX` guard used.

**Avoid these synonyms:** server, server session, tmux session.

### workspace

Herdr's per-project container for tabs, panes, and agents. It pages the
sidebar's rolled-up agent state by project.

**The mapping.** One tmux session maps to one herdr workspace inside a single
default herdr session. The convenience of the old per-project named tmux
sessions survives as per-project workspaces, and the sidebar shows all of them
at once. Not to be confused with the git worktree concept herdr also manages,
`worktrees.directory`, which spawns a grouped child workspace.

**Avoid these synonyms:** project in a tab, tmux session, worktree.