{
  config,
  pkgs,
  ...
}:
{
  home = {
    username = "dandyrow";
    homeDirectory = "/home/dandyrow";
    stateVersion = "25.11";

    packages = with pkgs; [
      # Dotfile tools
      bat
      btop
      eza
      fastfetch
      kitty
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
      nodePackages.npm
    ];

    # Dotfiles are managed as Nix store paths — edit in the repo and run
    # nixos-rebuild switch (NixOS) or home-manager switch (non-NixOS) to apply.
    file = {
      ".config/bat".source       = ../../bat/.config/bat;
      ".config/btop".source      = ../../btop/.config/btop;
      ".config/eza".source       = ../../eza/.config/eza;
      ".config/fastfetch".source = ../../fastfetch/.config/fastfetch;
      ".config/git".source       = ../../git/.config/git;
      ".config/kitty".source     = ../../kitty/.config/kitty;
      ".config/nvim".source      = ../../neovim/.config/nvim;
      ".config/starship".source  = ../../starship/.config/starship;
      ".config/tmux".source      = ../../tmux/.config/tmux;
      ".config/yazi".source      = ../../yazi/.config/yazi;
      ".config/zsh".source       = ../../zsh/.config/zsh;

      # gnupg: symlink individual files only — gpg requires strict 700 permissions
      # on the directory itself, and the directory contains runtime files that
      # should not be tracked in git.
      ".local/share/gnupg/gpg.conf".source      = ../../gnupg/.local/share/gnupg/gpg.conf;
      ".local/share/gnupg/gpg-agent.conf".source = ../../gnupg/.local/share/gnupg/gpg-agent.conf;
    };

    sessionVariables = {
      # Required by zsh config — tells zsh where to find its config files.
      ZDOTDIR = "${config.home.homeDirectory}/.config/zsh";
    };
  };
}
