{ config, pkgs, ... }:
{
  users.users.${config.dandyrow.primaryUser} = {
    extraGroups = [ "libvirtd" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsxeHA5DWcz/L4A1BpozhL/BTNepsGXfrINkfeZSmvJ dandyrow@WSL" # Work Nix WSL
    ];
  };

  users.groups.libvirtd = { };

  virtualisation.podman.enable = true;
  virtualisation.libvirtd.enable = true;

  programs.virt-manager.enable = true;

  environment.systemPackages = [ pkgs.podman-compose ];

  gnome.enable = true;

  # Coincides with the other hosts by install date, not by sharing — do not consolidate.
  system.stateVersion = "25.11";
}
