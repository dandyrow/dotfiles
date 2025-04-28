# dotfiles

This repo contains my configuration dotfiles for my Linux systems.
It is structured in such a way that GNU stow can be used to install the dotfiles
in their correct location within the target user's home directory.

This README lists any requirements and / or instructions that are required for
the dotfiles to be installed correctly. Below are the basic requirements common
to all dotfiles within this repo.

## Installing TLS Certs

To install TLS certs for use when the Arch linux environment is behind a corporate
proxy run the following command for each certificate that needs installed:
`# trust anchor --store myCA.crt`

On Debian systems copy the certificates to `/usr/local/share/ca-certificates`
with the file ending in .crt. Then run `update-ca-certificates` as root.

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
* zoxide
* ttf-dejavu-nerd _(nerdfont)_
* pkgfile _[arch]_ (optional)

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

## Fastfetch

### Requirements

* fastfetch

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
* curl
* wget
* unzip
* tar
* gzip
* ripgrep
* wl-clipboard
* git
* ttf-dejavu-nerd
* python
* python-pip
* github-cli
* npm
* gcc
* codespell
* stylua
* actionlint
* ansible-lint
* yamllint
* yamlfmt
* eslint

### Steps to install

1. Install requirements
2. Run `stow neovim` from within repo root.
