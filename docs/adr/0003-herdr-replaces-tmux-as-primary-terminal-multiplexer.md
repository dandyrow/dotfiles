# Herdr replaces tmux as the primary terminal multiplexer

The host's daily terminal flow was built on tmux: a custom `tmux.conf`, a
Nix-generated `plugins.conf` (resurrect + continuum), `vim-tmux-navigator`, and
`S`-style sessions. We adopt **herdr** (via the nixpkgs package, stowed
`config.toml`) as the default runtime because it matches the workflow better
out of the box — agent-aware sidebar with `idle/working/blocked/done` state,
native resume of agent sessions (opencode, copilot) after a reboot, system
notifications, and mouse-first interaction — while keeping tmux installed
untouched as a fallback until the migration is proven.

The mapping is one **tmux session → one herdr workspace** in a single default
herdr session. Muscle memory that survives: `ctrl+b` prefix, split
bindings, `prefix+[` vi copy mode (mouse drag-select becomes the primary
selection gesture; rectangle copy does not exist), cwd-following splits, and the
catppuccin theme (a herdr default). What is consciously lost: `C-h/j/k/l`
cross-boundary vim navigation (kept intra-vim only; `devxplay/herdr.nvim`
replays it but stays uninstalled until dogfooding settles it), and
resurrect-style process restoration — a reboot restores layout and fresh shells
in saved directories, plus native agent session resumes, rather than replaying
the old processes. `experimental.pane_history` is enabled so recent pane
contents also return.

## Considered Options

- Keeping tmux alone was rejected: no agent state visibility, no native
  conversation resume, and its defaults would need repeated custom config to
  match the workflow herdr ships.
- Replacing tmux immediately was rejected: the migration period relies on tmux
  staying fully available, so removal becomes a separate, later decision.
- Wire the opencode/copilot integrations with `herdr integration install`
  imperatively was rejected: their artifacts are declaratively Nix-linked
  instead (pinned `fetchFromGitHub` at the nixpkgs herdr rev, referenced from
  the store) so a fresh machine rebuilds them without runtime installs.