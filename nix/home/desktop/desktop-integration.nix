{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.dandyrow.hasDesktop {
  home.packages =
    (with pkgs; [
      kitty
    ])
    ++ (with pkgs.gnomeExtensions; [
      appindicator
      dash-to-dock
      status-area-horizontal-spacing
    ]);

  # Suppress CLI .desktop entries from the GNOME launcher.
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
