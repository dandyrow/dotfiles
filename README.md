# dotfiles
This repository contains my dotfiles to allow consistent configuration of software across different systems.

It is designed with GNU Stow in mind to allow for easy installation of the dotfiles. The folder structure within this repo is important as stow will create the same structure in the parent directory of where the repo is cloned to.

## Installation Instructions

1. Clone this repo to your home folder (can be cloned into a folder such as `.dotfiles` within `home`).
2. Change directory into the local clone of the repo.
3. Execute `stow <software_name>` replacing `<software_name>` with the name of the software you want to install the configuration for. (Note: a folder of this same name must exist within the repo).
