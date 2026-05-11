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
      pkgs = inputs.nixpkgs.legacyPackages.${system};

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

      hostDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./nix/hosts);
    in
    {
      nixosConfigurations = lib.mapAttrs (host: _: mkSystem host) hostDirs;

      homeConfigurations.dandyrow = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./nix/home ];
      };
    };
}
