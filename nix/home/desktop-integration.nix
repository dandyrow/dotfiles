{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.dandyrow.hasDesktop {
  home.packages = with pkgs.gnomeExtensions; [
    appindicator
    dash-to-dock
    status-area-horizontal-spacing
  ];

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

  dconf.settings = {
    "org/gnome/shell".enabled-extensions = [
      "appindicatorsupport@rgcjonas.gmail.com"
      "dash-to-dock@micxgx.gmail.com"
      "status-area-horizontal-spacing@mathematical.coffee.gmail.com"
    ];
  };
}
