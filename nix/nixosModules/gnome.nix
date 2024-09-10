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
    ]) ++ (with pkgs.gnome; [
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
    ]);

    environment.systemPackages = lib.mkIf config.gnome.enable-gnome-software [
      pkgs.gnome.gnome-software
    ];

    services.flatpak.enable = config.gnome.enable-gnome-software;
  };
}
