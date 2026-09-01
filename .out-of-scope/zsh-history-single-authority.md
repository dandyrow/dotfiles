# Zsh history single-authority consolidation

The NixOS system module and the user `.zshrc` both declare zsh history
settings. This is deliberate, not duplication to be consolidated.

## Why this is out of scope

The dotfiles' zsh config runs in two contexts that need the same settings
declared twice.

On a NixOS host, `programs.zsh.*` in the system module renders history into
the machine-wide `/etc/zshrc`. That file applies to every user, not just the
primary user. And the nixpkgs zsh module renders `SAVEHIST`/`HISTSIZE`/
`HISTFILE` unconditionally while `programs.zsh` is enabled, so the values
can't be fully delegated to a per-user file anyway.

On a standalone deployment, the user `.zshrc` (stowed to
`~/.config/zsh/.zshrc`) is the only history authority. There is no system
module there to do the job.

Making either side the single authority loses a context that needs it. If the
dotfiles module stops declaring its values, nixpkgs' default history block
(`setopt HIST_IGNORE_DUPS SHARE_HISTORY HIST_FCNTL_LOCK`, `HISTSIZE=2000`,
`$HOME/.zsh_history`) becomes effective on NixOS. If the user `.zshrc` block
is removed, standalone loses history configuration entirely.

Both declarations keep the same size and path values, and the user `.zshrc`
re-applies them at runtime, so the two contexts converge on the same
effective behaviour.

## Prior requests

- #137: "refactor(nix): make the user shell config the single authority for history"