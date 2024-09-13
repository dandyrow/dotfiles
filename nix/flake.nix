{
  description = "NixOS Config of dandyrow";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.4.1";
  };

  outputs = { nixpkgs, nix-flatpak, ... }@inputs: {
    nixosConfigurations = {
      LivsLaptop = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/LivsLaptop/configuration.nix
          ./nixosModules
          nix-flatpak.nixosModules.nix-flatpak
        ];
      };
    };
  };
}
