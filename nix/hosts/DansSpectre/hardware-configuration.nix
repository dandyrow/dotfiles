# Specific config for HP Spectre x360, Kaby Lake G.
#
# fileSystem settings are intentionally absent as disko generates it from disk-config.nix.
{ ... }:
{
  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usb_storage"
      "sd_mod"
    ];

    # kvm-intel: post-boot virtualisation module.
    # rtsx_pci + rtsx_pci_sdmmc: Realtek PCIe SD card reader (RTS522A).
    kernelModules = [
      "kvm-intel"
      "rtsx_pci"
      "rtsx_pci_sdmmc"
    ];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;

    # Kaby Lake G requires redistributable firmware blobs for the AMD GPU.
    enableRedistributableFirmware = true;

    bluetooth = {
      enable = true;
      # Power on the adapter at boot so it is ready without manual intervention.
      powerOnBoot = true;
    };
  };

  services.xserver.videoDrivers = [ "amdgpu" ];
}
