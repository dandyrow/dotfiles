{ lib, config, ... }:
{
# Kernel modules specific to DansSpectre
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = true;
  };

  systemd-boot.enable = true;

  gnome = {
    enable = true;
    enable-gnome-software = true;
  };

  zsh = {
    enable = true;
    defaultShell = true;
  };

  networking.hostName = "DansSpectre";

  services = {
    openssh.enable = true;
  };

  documentation.nixos.enable = false;
  gnupg.enable = true;

  programs = {
    command-not-found.enable = true;
    firefox.enable = true;
    git.enable = true;
    starship.enable = true;
    neovim.enable = true;
    steam.enable = true;
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
    ];

  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIForH9TNaNvQGNBzWXyPdtRGO5xiR2BYQeIKf8mzN2u9 dandyrow@Desktop"
      ];
    };

    dandyrow = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "print"
      ];
    };
  };

  system.stateVersion = "24.05";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
