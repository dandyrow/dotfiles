{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.timeout = 5;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.systemd-boot.configurationLimit = 14;

  gnome.enable = true;
  gnome.enable-gnome-software = true;

  networking.networkmanager.enable = true;

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
