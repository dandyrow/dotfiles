{ pkgs, lib, config, ... }: {
  options = {
    gnome.enable = lib.mkEnableOption "enables gnome";
    gnome.enable-gnome-software = lib.mkEnableOption "enables gnome software";
  };

  config = lib.mkIf config.gnome.enable {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = true;
      xkb.layout = "gb";
      excludePackages = [ pkgs.xterm ];
    };

    environment.gnome.excludePackages = (with pkgs; [
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
    ]);

    environment.systemPackages = lib.mkIf config.gnome.enable-gnome-software (with pkgs; [
      gnome-software
      gnome-tweaks
      gnomeExtensions.blur-my-shell
      gnomeExtensions.dash-to-dock
      gnomeExtensions.gnome-40-ui-improvements
    ]);

    services.flatpak.enable = config.gnome.enable-gnome-software;
  };
}
