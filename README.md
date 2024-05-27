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
* fastfetch
* fzf
* exa
* starship _(prompt)_
* ttf-dejavu-nerd _(nerdfont)_
* pkgfile _[arch]_
* command-not-found _[debian/ubuntu]_

### Steps to install

1. Install requirements listed above.
2. Run `stow zsh` from within repo root.
3. Set `ZDOTDIR` environment variable to `$HOME/.config/zsh` in `/etc/zsh/zprofile` or `/etc/zsh/zshenv` files for example to tell zsh where config is located using the line `export ZDOTDIR="$HOME/.config/zsh"`.

## Starship

### Requirements

* starship
* ttf-dejavu-nerd _(nerdfont)_

### Steps to install

1. Install requirements.
2. Run `stow starship` from within repo root.

## Neofetch

### Requirements

* neofetch

### Steps to install

1. Install requirements
2. Run `stow neofetch` from within repo root.

## Tmux

### Requirements

* Tmux

### Steps to install

1. Install requirements
2. Run `stow tmux` from within repo root.

## Zellij

### Requirements

* zellij

### Steps to install

1. Install requirements
2. Run `stow zellij` from within repo root.

## Git

### Requirements

* git

### Steps to install

1. Install requirements
2. Run `stow git` from within repo root.

## Neovim

### Requirements

* neovim
* gcc _(required for treesitter)_
* ripgrep _(required for telescope)_
* yamllint
* ansible-lint
* codespell
* proselint
* gitlint
* npm
* wget
* tree-sitter
* fd
* unzip
* wl-clipboard _[wayland desktop] (copy & paste to & from system clipboard)_
* ttf-dejavu-nerd _(nerdfont)_

### Steps to install

1. Install requirements
2. Run `stow neovim` from within repo root.
