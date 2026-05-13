{
  config,
  lib,
  pkgs,
  # osConfig is populated when running as a NixOS module; null in standalone HM.
  osConfig ? null,
  ...
}:
let
  dotfilesDir = "${config.home.homeDirectory}/.dotfiles";
  mkLink = relPath: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${relPath}";
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
        kitty
        neovim
        tmux
        yazi

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
    file = {
      ".config/bat".source = mkLink "bat/.config/bat";
      ".config/btop".source = mkLink "btop/.config/btop";
      ".config/eza".source = mkLink "eza/.config/eza";
      ".config/fastfetch".source = mkLink "fastfetch/.config/fastfetch";
      ".config/git".source = mkLink "git/.config/git";
      ".config/kitty".source = mkLink "kitty/.config/kitty";
      ".config/nvim".source = mkLink "neovim/.config/nvim";
      ".config/starship".source = mkLink "starship/.config/starship";
      ".config/tmux".source = mkLink "tmux/.config/tmux";
      ".config/yazi".source = mkLink "yazi/.config/yazi";
      ".config/zsh".source = mkLink "zsh/.config/zsh";

      # gnupg: manage individual files rather than the whole directory — gpg requires
      # strict 700 permissions on the directory itself, and the directory contains
      # runtime files (sockets, keyrings) that should not be managed by Nix.
      ".local/share/gnupg/gpg.conf".source = mkLink "gnupg/.local/share/gnupg/gpg.conf";
      ".local/share/gnupg/gpg-agent.conf".source = mkLink "gnupg/.local/share/gnupg/gpg-agent.conf";
    };

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
}
