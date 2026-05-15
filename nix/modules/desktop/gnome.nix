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
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };

      desktopManager.gnome.enable = true;
    };

    networking.networkmanager.enable = true;

    # Remove unwanted GNOME default applications entirely.
    environment.gnome.excludePackages = with pkgs; [
      epiphany # Web browser
      gnome-characters
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
