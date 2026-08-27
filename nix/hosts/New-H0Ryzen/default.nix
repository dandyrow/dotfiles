{ disko, ... }:

{
  imports = [
    ../../modules/base
    ../../modules/desktop/gnome.nix
    ./configuration.nix
    ./disk-config.nix
    disko.nixosModules.disko
  ];
}
