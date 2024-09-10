{
  description = "NixOS Config of dandyrow";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      LivsLaptop = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/LivsLaptop/configuration.nix
          ./nixosModules
        ];
      };
    };
  };
}
