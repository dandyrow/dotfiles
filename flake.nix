{
  description = "dandyrow's NixOS & Home Manager config";

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
    inputs@{ ... }:
    let
      system = "x86_64-linux";

      lib = inputs.nixpkgs.lib;

      mkSystem =
        host:
        lib.nixosSystem {
          inherit system;
          modules = [
            { networking.hostName = host; }
            ./nix/hosts/${host}
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.dandyrow = import ./nix/home;
            }
          ];

          specialArgs = {
            disko = inputs.disko;
          };
        };

      mkHome =
        hostSystem:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${hostSystem};
          modules = [ ./nix/home ];
        };

      hostDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./nix/hosts);
    in
    {
      nixosConfigurations = lib.mapAttrs (host: _: mkSystem host) hostDirs;

      homeConfigurations = {
        "dandyrow@x86_64-linux" = mkHome "x86_64-linux";
        "dandyrow@aarch64-linux" = mkHome "aarch64-linux";
      };
    };
}
