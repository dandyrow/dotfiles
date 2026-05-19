{
  description = "dandyrow's Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

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
            ./hosts/${host}
          ];

          specialArgs = {
            disko = inputs.disko;
          };
        };

      hostDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts);
    in
    {
      nixosConfigurations = lib.mapAttrs (host: _: mkSystem host) hostDirs;
    };
}
