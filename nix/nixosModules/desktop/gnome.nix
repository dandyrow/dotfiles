{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./printing.nix
    ./pipewire.nix
  ];

  options = {
    gnome = {
      enable = lib.mkEnableOption "gnome";
      enable-gnome-software = lib.mkEnableOption "extra gnome software packages";
    };
  };

  config = lib.mkIf config.gnome.enable {
    services = {
      xserver = {
        enable = true;
        xkb.layout = "gb";
        excludePackages = [ pkgs.xterm ];

        displayManager.gdm = {
          enable = true;
          wayland = true;
        };

        desktopManager.gnome.enable = true;
      };

      flatpak.enable = config.gnome.enable-gnome-software;
    };

    networking.networkmanager.enable = true;

    pipewire.enable = true;

    printing = {
      enable = lib.mkDefault true;
      passwordlessPrinterSetup = lib.mkDefault true;
    };

    environment = {
      gnome.excludePackages = (
        with pkgs;
        [
          gnome-tour
          xterm
          epiphany
          gnome-music
          geary
          gnome-characters
          tali
          iagno
          hitori
          atomix
          gnome-maps
          totem
          gnome-weather
          gnome-font-viewer
          gnome-text-editor
        ]
      );

      systemPackages = lib.mkIf config.gnome.enable-gnome-software (
        with pkgs;
        [
          gnome-software
          gnome-tweaks
          gnome-network-displays
          gnomeExtensions.blur-my-shell
          gnomeExtensions.dash-to-dock
          gnomeExtensions.gnome-40-ui-improvements
        ]
      );
    };
  };
}
