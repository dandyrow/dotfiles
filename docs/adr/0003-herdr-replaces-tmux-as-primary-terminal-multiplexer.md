# Herdr replaces tmux as the primary terminal multiplexer

The host's daily terminal flow was built on tmux: a custom `tmux.conf`, a
Nix-generated `plugins.conf` (resurrect + continuum), `vim-tmux-navigator`, and
single-letter sessions. **Herdr** (nixpkgs package, stowed `config.toml`)
replaces it as the default runtime because its defaults match the workflow
already. The sidebar rolls agent state up per project in
`idle/working/blocked/done`. Agent conversations resume natively after a
reboot, notifications reach the system desktop, and interaction is mouse-first
by design. tmux stays installed untouched as a fallback until the migration is
proven.

The mapping is one tmux session to one herdr workspace, inside a single
default herdr session.

**What survives.** The `ctrl+b` prefix, split bindings, and `prefix+[` vi copy
mode. Mouse drag-select becomes the primary selection gesture; rectangle copy
does not exist. Splits still follow cwd. The catppuccin theme is a herdr
default.

**What is lost.** `C-h/j/k/l` cross-boundary vim navigation, kept intra-vim
only. `devxplay/herdr.nvim` would restore it, but stays uninstalled until we
have run the native keymaps long enough to know we want it. Resurrect-style
process restoration is not ported: a reboot brings the layout back, fresh
shells in saved directories, and native agent session resumes, but not the old
processes. `experimental.pane_history` is enabled so recent pane contents also
come back.

## Considered Options

- Keeping tmux alone was rejected: no agent state visibility, no native
  conversation resume, and its defaults still need custom config to match what
  herdr ships.
- Replacing tmux immediately was rejected: the migration period relies on tmux
  staying fully available, so removal becomes a separate, later decision.
- Running `herdr integration install` imperatively was rejected: the integration
  artifacts are Nix-linked instead, taken from the herdr package's own `src` so
  they track every nixpkgs bump, and a fresh machine rebuilds them without
  runtime installs.