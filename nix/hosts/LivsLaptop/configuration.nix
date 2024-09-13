{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  systemd-boot.enable = true;
  systemd-boot.logo = true;
  systemd-boot.theme = "breeze";

  gnome.enable = true;
  gnome.enable-gnome-software = true;
  services.flatpak.packages = [
    "org.mozilla.firefox"
    "org.libreoffice.LibreOffice"
  ];

  printing.enable = true;
  passwordless-printer-setup.enable = true;

  networking.hostName = "LivsLaptop";

  documentation.nixos.enable = false;

  # Replace this in modules later
  environment.systemPackages = with pkgs; [
    git
  ];

  users.users.dandyrow = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "print" ];
  };

  users.users.olivia = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "print" ];
  };

  system.stateVersion = "24.05";
}
