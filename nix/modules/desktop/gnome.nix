{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.gnome.enable = lib.mkEnableOption "GNOME desktop";

  config = lib.mkIf config.gnome.enable {
    # Hardware graphics acceleration is required for Wayland compositing.
    hardware.graphics.enable = true;

    services = {
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    networking.networkmanager.enable = true;

    # Dark mode default + green accent; user can still override in GNOME Settings.
    programs.dconf.profiles.user.databases = [
      {
        settings."org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          accent-color = "green";
        };
      }
    ];

    # Qt apps use adwaita-dark to match GNOME's dark theme.
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

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
