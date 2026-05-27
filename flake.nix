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

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ ... }:
    let
      system = "x86_64-linux";

      lib = inputs.nixpkgs.lib;

      allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "github-copilot-cli"
          "docker-sbx"
          "steam"
          "steam-original"
          "steam-run"
          "steam-unwrapped"
        ];

      overlays = [
        (final: prev: {
          docker-sbx = final.callPackage ./nix/pkgs/docker-sbx.nix { };
          # Track a newer upstream than nixos-unstable currently ships; drop
          # this override when nixpkgs catches up.
          github-copilot-cli = final.callPackage ./nix/pkgs/github-copilot-cli.nix { };
        })
      ];

      mkSystem =
        host:
        lib.nixosSystem {
          inherit system;
          modules = [
            {
              networking.hostName = host;
              nixpkgs.overlays = overlays;
              nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;
            }
            ./nix/hosts/${host}
            inputs.home-manager.nixosModules.home-manager
            inputs.nix-index-database.nixosModules.nix-index
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.dandyrow = import ./nix/home;
              # Prevent activation failures when HM wants to overwrite pre-existing files.
              home-manager.backupFileExtension = "bak";
            }
          ]
          ++ lib.optionals (host == "WSL") [
            inputs.nixos-wsl.nixosModules.default
          ];

          specialArgs = {
            disko = inputs.disko;
          };
        };

      mkHome =
        {
          hostSystem,
          wsl ? false,
        }:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = hostSystem;
            inherit overlays;
            # config here applies only to standalone homeConfigurations.
            # For NixOS-managed users, useGlobalPkgs = true means NixOS pkgs are used,
            # and the unfree predicate is applied via nixpkgs.config in mkSystem instead.
            config = { inherit allowUnfreePredicate; };
          };
          modules = [ ./nix/home ];
          extraSpecialArgs = { inherit wsl; };
        };

      hostDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./nix/hosts);
    in
    {
      nixosConfigurations = lib.mapAttrs (host: _: mkSystem host) hostDirs;

      packages.${system}.wsl-tarball =
        inputs.self.nixosConfigurations.WSL.config.system.build.tarballBuilder;

      homeConfigurations = {
        "dandyrow@x86_64-linux" = mkHome { hostSystem = "x86_64-linux"; };
        "dandyrow@aarch64-linux" = mkHome { hostSystem = "aarch64-linux"; };
        "dandyrow@wsl" = mkHome {
          hostSystem = "x86_64-linux";
          wsl = true;
        };
      };
    };
}
