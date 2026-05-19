{
  description = "dandyrow's NixOS Configs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-flatpak,
      disko,
      home-manager,
      ...
    }@inputs:
    {
      nixosConfigurations = {

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

        DansSpectre = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            { nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ]; }
            ./hosts/DansSpectre/configuration.nix
            ./hosts/DansSpectre/disk-config.nix
            ./nixosModules
          ];
        };
      };

      homeConfigurations.dandyrow = home-manager.lib.homeManagerConfiguration {
        modules = [
          ./home
        ];
      };
    };
}
