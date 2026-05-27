{ ... }:
{
  # Needs these kernel modules to boot
  boot.initrd.availableKernelModules = [
    "uhci_hcd"
    "ehci_pci"
    "ahci"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];

  services.qemuGuest.enable = true;

  documentation.nixos.enable = false;

  programs = {
    git.enable = true;
    steam.enable = true;
  };

  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIForH9TNaNvQGNBzWXyPdtRGO5xiR2BYQeIKf8mzN2u9 dandyrow@Desktop"
      ];
    };

    dandyrow.extraGroups = [
      "networkmanager"
      "print"
    ];
  };

  system.stateVersion = "25.11";
}
