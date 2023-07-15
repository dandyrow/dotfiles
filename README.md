# dotfiles

This repo contains my configuration dotfiles for my linux systems. 
It is structured in such a way that GNU stow can be used to install the dotfiles
in their correct location within the target user's home directory.

This README lists any requirements and / or instructions that are required for
the dotfiles to be installed correctly. Below are the basic requirements common
to all dotfiles within this repo.

### Requirements

* git
* stow

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
