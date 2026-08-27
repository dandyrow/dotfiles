# The primary user's name is declared once, not derived

The login name of the human this machine belongs to is declared as an option
(`dandyrow.primaryUser`, `types.str`, defaulting to `"dandyrow"`) and referenced
everywhere the name was previously a literal: the user definition, the dotfiles
clone adapter, git's `safe.directory`, the `networkmanager` and `print` group
memberships, the WSL default user, the `sbx-daemon` service user, the `docker`
group, the host `authorizedKeys` path, and the flake's Home Manager user
attribute. Renaming the user on a NixOS host is a one-line edit, and a single
host can override the name without `mkForce`.

The name **cannot** be derived from the configuration. Filtering `users.users`
for the single `isNormalUser` entry and defining `users.users.<that name>` asks
the module system to merge the definition being written in order to learn its
own name; nix answers `error: infinite recursion encountered`. This is the first
alternative any reader reaches for, and it is a hard limit rather than a matter
of taste.

Occurrences of the string `dandyrow` that mean something other than "the Linux
user on this machine" stay literal on purpose: the GitHub account segment of the
clone URL (coupling it would repoint the repo at a URL that does not exist), the
`homeConfigurations` output names (user-facing CLI strings, documented in the
README, and evaluated outside any module so structurally out of reach anyway),
the flake description, the comment fields inside SSH public keys, and the
clone-dotfiles test fixtures.

The password-hash file is the one site that names the *role* instead. It sits at
`/etc/secrets/primary-user-password` — not at a path built from the option — so
the installer, which is shell and cannot read a NixOS option without evaluating
the flake, needs no derivation and a rename cannot desynchronise it. Following
the name would have been strictly worse than not having to follow it.

## Considered Options

**Declaring the name in the flake** and threading it into modules via
`specialArgs` was rejected. It reaches the same one-place goal, but it moves
ownership of a fact away from the module that materialises the user and makes
that module unusable on its own. An option keeps the module self-contained and
gets per-host override for free.

**Deriving the Home Manager name from `osConfig`** was rejected as unnecessary
rather than wrong. Home Manager's NixOS module already sets `home.username` and
`home.homeDirectory` from `users.users.<name>`, where `<name>` is the attribute
the user is registered under — so routing the flake's Home Manager user
attribute through the NixOS option is sufficient, and the Home Manager
declaration is consumed only on the standalone path where `osConfig` is null by
definition.
