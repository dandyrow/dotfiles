{ pkgs, inputs, ... }: {
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
    "org.onlyoffice.desktopeditors"
  ];

  printing.enable = true;
  passwordless-printer-setup.enable = true;

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
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "23:00";
    randomizedDelaySec = "45min";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
