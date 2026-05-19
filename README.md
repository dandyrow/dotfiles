# dotfiles

This repo contains my configuration dotfiles and NixOS system configuration for my Linux systems.

## Nix

The `nix/` directory contains a NixOS configuration and Home Manager setup managed with Nix flakes.
The flake at the repo root controls everything — NixOS hosts, home configuration, and dotfile deployment.

### Prerequisites

- Target machine booted into a NixOS live ISO (for fresh installs)
- A `secrets/` directory containing `etc/secrets/dandyrow-password` (bcrypt-hashed password)
  - Generate with: `mkpasswd -m bcrypt`

### Install NixOS on a new machine

Boot the target into a NixOS live ISO, then from this repo run:

```bash
./install.sh <host> <target-ip> ./secrets
```

Available hosts: `DansSpectre`, `New-H0Ryzen`

### Apply config changes (bare-metal NixOS)

From a local clone:
```bash
doas nixos-rebuild switch --flake /path/to/repo#<host>
```

Or directly from GitHub (requires changes to be pushed first):
```bash
doas nixos-rebuild switch --flake github:dandyrow/dotfiles#<host>
```

> **Note:** Dotfile edits made in `~/.dotfiles` take effect immediately — no rebuild needed.
> Only NixOS module changes (packages, services, users, etc.) require `nixos-rebuild switch`.

### Install on WSL2

#### Prerequisites

- Windows 11 or WSL version ≥ 0.67.6 (required for systemd support)
- WSL installed and enabled on the Windows host

#### 1. Build the NixOS-WSL tarball

From a clone of this repo on any x86_64 Linux machine with Nix:

```bash
nix build .#wsl-tarball
./result/bin/nixos-wsl-tarball-builder nixos.wsl
```

This produces `nixos.wsl` — a compressed archive ready to import into WSL.

#### 2. Import the tarball into WSL

From PowerShell or Command Prompt on Windows:

```powershell
wsl --import NixOS C:\Users\<you>\NixOS \\wsl$\<distro>\path\to\nixos.wsl
```

Or copy `nixos.wsl` to Windows first and import from there:

```powershell
wsl --import NixOS C:\Users\<you>\NixOS nixos.wsl
```

#### 3. Start NixOS

```powershell
wsl -d NixOS
```

The dotfiles repo is cloned to `~/.dotfiles` automatically on first boot during
system activation.

> **Note:** The WSL host uses `doas` (not `sudo`) after the first boot.

To apply config changes run the same command as for basre-metal NixOS systems
mentioned above.

#### Differences from bare-metal hosts

- No bootloader, initrd, or kernel configuration — WSL provides the kernel.
- No desktop environment, audio (PipeWire), or printing (CUPS).
- Desktop packages (`kitty`) are excluded from the Home Manager environment.
- Windows drives are automounted under `/mnt` (e.g. `/mnt/c`).
- Windows executables can be run directly from the shell.
- Networking and DNS are managed by WSL, not NixOS.

### Standalone Home Manager (non-NixOS Linux)

Replace `x86_64-linux` with `aarch64-linux` if on an ARM machine.

```bash
nix run nixpkgs#home-manager -- switch --flake github:dandyrow/dotfiles#dandyrow@x86_64-linux
```

> **Note:** `ttf-dejavu-nerd` must be installed manually on non-NixOS systems.

---

This README also lists any requirements and instructions required for the dotfiles to be installed
correctly on non-Nix systems. Below are the basic requirements common to all dotfiles.

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
2. Run `stow fastfetch` from within repo root.

## Tmux

### Requirements

* Tmux

### Steps to install

1. Install requirements
2. Run `stow tmux` from within repo root.

## Zellij

> **Note:** Zellij config is kept in this repo for reference but is not actively used and is not installed by the Nix config.

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
* fd
* tree-sitter
* wl-clipboard
* git
* ttf-dejavu-nerd
* python
* python-pip
* github-cli
* npm
* gcc
* make
* codespell
* stylua
* actionlint
* ansible-lint
* yamllint
* yamlfmt
* eslint

### Steps to install

1. Install requirements
2. Run `stow nvim` from within repo root.
