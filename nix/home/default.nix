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
        opencode
      ]
      # Only install kitty on systems with Gnome desktop environment
      ++ lib.optionals (osConfig != null && (osConfig.gnome.enable or false)) [
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

        # Neovim LSP / formatter / linter / DAP tools
        # On Nix, Mason is disabled (Mason binaries are broken in the non-FHS environment).
        # All tools that Mason would otherwise install must be provided here instead.
        # Keep this list in sync with nvim/.config/nvim/lua/config/tools.lua and
        # the servers table in nvim/.config/nvim/lua/plugins/lsp.lua.

        # LSP servers
        lua-language-server
        rust-analyzer
        bash-language-server
        basedpyright
        # gh_actions_ls (github-actions-language-server) is not yet in nixpkgs;
        # it will fall back to Mason on non-Nix systems or be unavailable on Nix.
        vscode-langservers-extracted # provides jsonls
        gopls
        ansible-language-server
        typescript-language-server
        nixd

        # Formatters
        beautysh
        ruff
        ansible-lint
        yamlfmt
        gofumpt
        # goimports is not available as a standalone package in nixpkgs; gotools
        # conflicts with gopls. goimports functionality is covered by gopls on Nix.
        eslint_d
        nixfmt # nixfmt-rfc-style is now an alias for nixfmt

        # Linters
        shellcheck
        actionlint
        golangci-lint

        # DAP adapters
        delve
        python3Packages.debugpy
        vscode-extensions.vadimcn.vscode-lldb # codelldb
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        # docker-sbx is only published for x86_64-linux; no aarch64 release.
        pkgs.docker-sbx
      ]
      # gnupg is provided system-wide on NixOS via the gnupg common module;
      # only add it here for standalone Home Manager (non-NixOS).
      ++ lib.optionals (osConfig == null) [ pkgs.gnupg ];

    # Dotfiles are symlinked from ~/.dotfiles — a clone of the dotfiles repo.
    # On NixOS the clone is created during system activation (see modules/common/dotfiles.nix).
    # On non-NixOS the clone is created by the cloneDotfiles activation script below.
    file =
      let
        hasDesktop = osConfig != null && (osConfig.gnome.enable or false);
      in
      lib.mkMerge [
        (mkConfigLink "bat")
        (mkConfigLink "btop")
        (mkConfigLink "eza")
        (mkConfigLink "fastfetch")
        (mkConfigLink "git")
        (mkConfigLink "npm")
        (mkConfigLink "nvim")
        (mkConfigLink "opencode")
        (mkConfigLink "starship")
        (mkConfigLink "tmux")
        (mkConfigLink "yazi")
        (mkConfigLink "zsh")
        (lib.optionalAttrs hasDesktop (mkConfigLink "kitty"))

        # Work-specific git config included via includeIf in the main git config.
        # Sets work email and disables GPG signing for all repos under ~/Projects/work/.
        {
          "Projects/work/.gitconfig".text = ''
            [user]
              name = Daniel Lowry
              email = daniel.lowry@kainos.com

            [commit]
              gpgSign = false

            [tag]
              gpgSign = false
          '';
        }

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
  systemd.user = {
    sessionVariables = {
      GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    };
    # gpg requires strict 700 permissions on its home directory.
    tmpfiles.rules = [
      "d %h/.local/share/gnupg 0700 - - -"
    ];
  };

  # Hide CLI tools from the GNOME app menu. These packages ship .desktop files
  # so GNOME picks them up and shows them in the app launcher, but they are
  # terminal applications and have no business appearing there. Overriding each
  # entry with NoDisplay=true removes them from the menu while keeping the
  # binaries fully available in the terminal.
  xdg.desktopEntries = {
    btop = {
      name = "btop++";
      noDisplay = true;
    };
    nvim = {
      name = "Neovim";
      noDisplay = true;
    };
    yazi = {
      name = "Yazi";
      noDisplay = true;
    };
  };

  # Move ~/.nix-defexpr and ~/.nix-profile to XDG state directory.
  # use-xdg-base-directories is enabled system-wide in common/default.nix.
  nix.assumeXdg = true;
}
