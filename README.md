# dotfiles
Repository containing my configuration dotfiles

## Zsh

### Requirements

* zsh
* zsh-autosuggestions
* zsh-syntax-highlighting
* pkgfile

### Steps to install

1. Install requirements listed above.
2. Run `stow zsh` from within repo root.
3. Set `ZDOTDIR` environment variable to `$HOME/.config/zsh` in `/etc/zsh/zprofile` or `/etc/zsh/zshenv` files for example to tell zsh where config is located using the line `export ZDOTDIR="$HOME/.config/zsh"`.
