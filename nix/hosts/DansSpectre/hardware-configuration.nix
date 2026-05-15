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

    # i915: early KMS for the Intel iGPU, which drives the built-in display on
    # Kaby Lake G. Must be in initrd so the display is available before GDM
    # starts, otherwise GDM hangs on a grey screen and falls back to the login.
    initrd.kernelModules = [ "i915" ];

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

  # Kaby Lake G has two GPUs in the same package:
  #   - Intel iGPU (i915 / modesetting): drives the internal laptop display.
  #   - AMD Radeon RX Vega M (amdgpu): handles 3D rendering and external outputs.
  # Both drivers must be listed. Listing only "amdgpu" causes GDM to start on
  # the AMD card, find no display connected to it, and loop back to the login.
  services.xserver.videoDrivers = [
    "modesetting"
    "amdgpu"
  ];
}
