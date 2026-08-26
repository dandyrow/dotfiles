{
  config,
  lib,
  pkgs,
  mattPocockSkills,
  ...
}:
{
  imports = [
    ./clone-dotfiles.nix
    ./desktop-integration.nix
    ./desktop.nix
    ./dotfiles.nix
    ./firefox.nix
    ./gnupg-home.nix
    ./kitty.nix
    ./nvim-tools.nix
    ./primary-user.nix
    ./theme.nix
  ];

  home = {
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
        opencode

        # VS Code AI SBX tools
        bubblewrap
        socat
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
        github-copilot-cli
        gnumake
        python3
        ripgrep
        stylua
        tree-sitter
        unzip
        wl-clipboard
        yamllint
        nodejs
        wget
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        # docker-sbx is only published for x86_64-linux; no aarch64 release.
        pkgs.docker-sbx
      ];
  };

  xdg.dataFile."agents/skills/mattpocock".source = "${mattPocockSkills}/skills";

  # Move nix profile paths into XDG state directory.
  nix.assumeXdg = true;
}
