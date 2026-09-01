{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ../base/pipewire.nix
    ../base/printing.nix
    ./desktop-packages.nix
  ];

  options.gnome.enable = lib.mkEnableOption "GNOME desktop";

  config = lib.mkIf config.gnome.enable {
    pipewire.enable = true;
    printing.enable = true;
    # Hardware graphics acceleration is required for Wayland compositing.
    hardware.graphics.enable = true;

    services = {
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    networking.networkmanager.enable = true;
    users.users.${config.dandyrow.primaryUser}.extraGroups = [ "networkmanager" ];

    services.gnome.gnome-browser-connector.enable = true;

    environment.systemPackages = with pkgs.gnomeExtensions; [
      appindicator
      dash-to-dock
      status-area-horizontal-spacing
    ];

    programs.dconf.profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            accent-color = "green";
          };
          "org/gnome/shell".always-show-log-out = true;
          "org/gnome/shell".enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
            "dash-to-dock@micxgx.gmail.com"
            "status-area-horizontal-spacing@mathematical.coffee.gmail.com"
          ];
        };
      }
    ];

    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    # qgnomeplatform forces Qt5 apps to XCB/XWayland even in a Wayland session; this overrides it.
    environment.sessionVariables.QT_QPA_PLATFORM = "wayland;xcb";

    # Remove unwanted GNOME default applications entirely.
    environment.gnome.excludePackages = with pkgs; [
      decibels # Audio player
      epiphany # Web browser
      gnome-characters
      gnome-console # Terminal emulator (kitty is used instead)
      gnome-contacts
      gnome-font-viewer
      gnome-maps
      gnome-music
      gnome-text-editor
      gnome-tour
      gnome-weather
      showtime # Video player (replaces totem)
      totem # Video player (older name, kept for safety)
      yelp # Help / GNOME user docs
    ];
  };
}
