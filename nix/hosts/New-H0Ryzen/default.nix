{ disko, ... }:

{
  imports = [
    ../../modules/common
    ../../modules/profiles/desktop.nix
    ./configuration.nix
    ./disk-config.nix
    disko.nixosModules.disko
  ];
}
