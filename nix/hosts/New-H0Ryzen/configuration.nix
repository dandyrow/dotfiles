{ ... }:
{
  systemd-boot.enable = true;
  # Needs these kernel modules to boot
  boot.initrd.availableKernelModules = [
    "uhci_hcd"
    "ehci_pci"
    "ahci"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];

  gnome = {
    enable = true;
    enable-gnome-software = true;
  };

  printing.enable = true;

  zsh = {
    enable = true;
    defaultShell = true;
  };

  passwordless-printer-setup.enable = true;

  networking.hostName = "New-H0Ryzen";
  services.qemuGuest.enable = true;

  documentation.nixos.enable = false;

  programs = {
    command-not-found.enable = true;
    firefox.enable = true;
    git.enable = true;
    starship.enable = true;
    neovim.enable = true;
  };

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
