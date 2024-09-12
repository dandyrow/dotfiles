{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  systemd-boot.enable = true;

  networking = {
    hostName = "LivsLaptop";
    networkmanager.enable = true;
  };

  gnome.enable = true;
  gnome.enable-gnome-software = true;

  documentation.nixos.enable = false;

  time.timeZone = "Europe/London";

  console.keyMap = "uk";

  # Replace this in modules later
  environment.systemPackages = with pkgs; [
    git
  ];

  users.users.dandyrow = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  system.stateVersion = "24.05";
}
