{
  config,
  lib,
  pkgs,
  # osConfig is populated when running as a NixOS module; null in standalone HM.
  osConfig ? null,
  # wsl = true omits packages that don't work in a WSL environment.
  wsl ? false,
  ...
}:
let
  dotfilesDir = "${config.home.homeDirectory}/.dotfiles";
  mkLink = relPath: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${relPath}";
  mkConfigLink = name: { ".config/${name}".source = mkLink "${name}/.config/${name}"; };
in
{
  home = {
    username = "dandyrow";
    homeDirectory = "/home/dandyrow";
    stateVersion = "25.11";

    packages =
      with pkgs;
      [
        # Dotfile tools
        bat
        btop
        eza
        fastfetch
        neovim
        tmux
        yazi
      ]
      ++ lib.optionals (!wsl) [
        kitty
      ]
      ++ [
        # Zsh dependencies (see zsh dotfile README)
        fzf
        starship
        zoxide

        # Neovim dependencies (see neovim dotfile README)
        fd
        gcc
        gh
        gnumake
        python3
        ripgrep
        stylua
        tree-sitter
        unzip
        wl-clipboard
        yamllint
        nodejs
      ]
      # gnupg is provided system-wide on NixOS via the gnupg common module;
      # only add it here for standalone Home Manager (non-NixOS).
      ++ lib.optionals (osConfig == null) [ pkgs.gnupg ];

    # Dotfiles are symlinked from ~/.dotfiles — a clone of the dotfiles repo.
    # On NixOS the clone is created during system activation (see modules/common/dotfiles.nix).
    # On non-NixOS the clone is created by the cloneDotfiles activation script below.
    file = lib.mkMerge [
      (mkConfigLink "bat")
      (mkConfigLink "btop")
      (mkConfigLink "eza")
      (mkConfigLink "fastfetch")
      (mkConfigLink "git")
      (mkConfigLink "kitty")
      (mkConfigLink "nvim")
      (mkConfigLink "starship")
      (mkConfigLink "tmux")
      (mkConfigLink "yazi")
      (mkConfigLink "zsh")
      (mkConfigLink "npm")

      # gnupg: manage individual files rather than the whole directory — gpg requires
      # strict 700 permissions on the directory itself, and the directory contains
      # runtime files (sockets, keyrings) that should not be managed by Nix.
      {
        ".local/share/gnupg/gpg.conf".source = mkLink "gnupg/.local/share/gnupg/gpg.conf";
        ".local/share/gnupg/gpg-agent.conf".source = mkLink "gnupg/.local/share/gnupg/gpg-agent.conf";
      }
    ];

    # On non-NixOS: clone the dotfiles repo if not already present before
    # symlinks are created. On NixOS this is handled by the system activation
    # script in modules/common/dotfiles.nix and this block is omitted.
    activation = lib.mkIf (osConfig == null) {
      cloneDotfiles = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
        if [ ! -d "${dotfilesDir}" ]; then
          ${pkgs.git}/bin/git clone \
            https://github.com/dandyrow/dotfiles.git \
            "${dotfilesDir}"
        fi
      '';
    };
  };

  # GNUPGHOME must be in the systemd user environment so gpg-agent (launched
  # as a systemd user service at login) uses the XDG path rather than ~/.gnupg.
  systemd.user.sessionVariables = {
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";
  };

  # Move ~/.nix-defexpr and ~/.nix-profile to XDG state directory.
  # use-xdg-base-directories is enabled system-wide in common/default.nix.
  nix.assumeXdg = true;
}
