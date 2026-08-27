{ disko, ... }:

{
  imports = [
    ../../modules/base
    ../../modules/desktop/gnome.nix
    ./hardware-configuration.nix
    ./configuration.nix
    ./disk-config.nix
    disko.nixosModules.disko
  ];
}
