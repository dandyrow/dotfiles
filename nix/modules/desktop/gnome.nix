{ lib, config, ... }:
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
  };
}
