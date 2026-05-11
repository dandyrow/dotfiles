{
  config,
  pkgs,
  dotfilesRoot,
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
      ".config/bat".source = dotfilesRoot + "/bat/.config/bat";
      ".config/btop".source = dotfilesRoot + "/btop/.config/btop";
      ".config/eza".source = dotfilesRoot + "/eza/.config/eza";
      ".config/fastfetch".source = dotfilesRoot + "/fastfetch/.config/fastfetch";
      ".config/git".source = dotfilesRoot + "/git/.config/git";
      ".config/kitty".source = dotfilesRoot + "/kitty/.config/kitty";
      ".config/nvim".source = dotfilesRoot + "/neovim/.config/nvim";
      ".config/starship".source = dotfilesRoot + "/starship/.config/starship";
      ".config/tmux".source = dotfilesRoot + "/tmux/.config/tmux";
      ".config/yazi".source = dotfilesRoot + "/yazi/.config/yazi";
      ".config/zsh".source = dotfilesRoot + "/zsh/.config/zsh";

      # gnupg: manage individual files rather than the whole directory — gpg requires
      # strict 700 permissions on the directory itself, and the directory contains
      # runtime files (sockets, keyrings) that should not be managed by Nix.
      ".local/share/gnupg/gpg.conf".source = dotfilesRoot + "/gnupg/.local/share/gnupg/gpg.conf";
      ".local/share/gnupg/gpg-agent.conf".source =
        dotfilesRoot + "/gnupg/.local/share/gnupg/gpg-agent.conf";
    };

    sessionVariables = {
      # Required by zsh config — tells zsh where to find its config files.
      ZDOTDIR = "${config.home.homeDirectory}/.config/zsh";
    };
  };
}
