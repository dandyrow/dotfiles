{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  systemd-boot = {
    enable = true;
    logo = true;
    theme = "breeze";
  };

  gnome = {
    enable = true;
    enable-gnome-software = true;
  };

  services.flatpak.packages = [
    "org.mozilla.firefox"
    "org.onlyoffice.desktopeditors"
  ];

  networking.hostName = "LivsLaptop";

  documentation.nixos.enable = false;

  # Replace this in modules later
  environment.systemPackages = with pkgs; [
    git
  ];

  users.users.olivia = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "print" ];
  };

  system.stateVersion = "24.05";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
