{
  config,
  lib,
  pkgs,
  mattPocockSkills,
  # No default — HM always supplies it, null off NixOS.
  osConfig,
  ...
}:
let
  nvimToolsJson = builtins.fromJSON (builtins.readFile ../../nvim/.config/nvim/lua/config/tools.json);
  nvimToolAttrs = lib.unique (
    map (t: if t ? nixpkgsAttr then t.nixpkgsAttr else t.name) (
      lib.filter (t: !(t.masonOnly or false)) nvimToolsJson
    )
  );
  nvimToolPackages = map (attr: lib.getAttrFromPath (lib.splitString "." attr) pkgs) nvimToolAttrs;
in
{
  imports = [
    ./clone-dotfiles.nix
    ./desktop.nix
    ./dotfiles.nix
    ./firefox.nix
    ./primary-user.nix
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
      ++ lib.optionals config.dandyrow.hasDesktop [
        kitty
      ]
      ++ lib.optionals config.dandyrow.hasDesktop (
        with pkgs.gnomeExtensions;
        [
          appindicator
          dash-to-dock
          status-area-horizontal-spacing
        ]
      )
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
      ++ nvimToolPackages
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        # docker-sbx is only published for x86_64-linux; no aarch64 release.
        pkgs.docker-sbx
      ]
      # gnupg is provided system-wide on NixOS via the gnupg common module;
      # only add it here for standalone Home Manager (non-NixOS).
      ++ lib.optionals (osConfig == null) [ pkgs.gnupg ];
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

  xdg.dataFile."agents/skills/mattpocock".source = "${mattPocockSkills}/skills";

  # Wire Firefox up as the default browser so xdg-open (used by kitty and
  # other tools) can resolve http/https URLs to a handler.
  xdg.mimeApps = lib.mkIf config.dandyrow.hasDesktop {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "text/html" = "firefox.desktop";
    };
  };

  # Hide packages from the GNOME app menu that have no place in the launcher.
  # These ship .desktop files that GNOME picks up automatically; overriding
  # each entry with NoDisplay=true suppresses the menu entry while keeping the
  # package fully functional.
  xdg.desktopEntries = {
    btop = {
      name = "btop++";
      noDisplay = true;
    };
    cups = {
      name = "Manage Printing";
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

  catppuccin = {
    enable = true;
    autoEnable = false;
    flavor = "mocha";
    accent = "green";
    firefox = lib.mkIf config.dandyrow.hasDesktop {
      enable = true;
      force = true;
    };
  };

  gtk = lib.mkIf config.dandyrow.hasDesktop {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "green";
      };
    };
  };

  dconf.settings = lib.mkIf config.dandyrow.hasDesktop {
    "org/gnome/desktop/interface".icon-theme = lib.mkDefault "Papirus-Dark";
    "org/gnome/shell".enabled-extensions = [
      "appindicatorsupport@rgcjonas.gmail.com"
      "dash-to-dock@micxgx.gmail.com"
      "status-area-horizontal-spacing@mathematical.coffee.gmail.com"
    ];
  };
}
