{
  description = "NixOS Config of dandyrow";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.4.1";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      nix-flatpak,
      disko,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        LivsLaptop = nixpkgs.lib.nixosSystem {
          modules = [
            ./hosts/LivsLaptop/configuration.nix
            ./nixosModules
            nix-flatpak.nixosModules.nix-flatpak
          ];
        };

        New-H0Ryzen = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            { nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; }
            ./hosts/New-H0Ryzen/configuration.nix
            ./hosts/New-H0Ryzen/disk-config.nix
            ./nixosModules
          ];
        };
      };
    };
}
