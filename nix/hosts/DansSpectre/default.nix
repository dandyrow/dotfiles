{ disko, ... }:

{
  imports = [
    ../../modules/common
    ../../modules/profiles/desktop.nix
    ./hardware-configuration.nix
    ./configuration.nix
    ./disk-config.nix
    disko.nixosModules.disko
  ];
}
