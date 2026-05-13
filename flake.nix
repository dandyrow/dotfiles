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
  };

  outputs =
    inputs@{ ... }:
    let
      system = "x86_64-linux";

      lib = inputs.nixpkgs.lib;

      overlays = [
        (final: prev: {
          xdg-user-dirs = prev.xdg-user-dirs.overrideAttrs (old: rec {
            version = "0.20";
            src = prev.fetchurl {
              url = "https://user-dirs.freedesktop.org/releases/xdg-user-dirs-${version}.tar.xz";
              hash = "sha256-uONChiePT+8+G/6WhcOVzMDrUMFNOi+0lT3QD7/Trzk=";
            };
            preFixup = ''
              # fallback values need to be last
              wrapProgram "$out/bin/xdg-user-dirs-update" \
                --suffix XDG_CONFIG_DIRS : "$out/etc/xdg"

              # Autostart, because the installed service is never explicitly enabled in NixOS
              substituteInPlace "$out/etc/xdg/autostart/xdg-user-dirs.desktop" \
                --replace-fail "X-systemd-skip=true" "X-systemd-skip=false"
            '';
          });
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
            }
            ./nix/hosts/${host}
            inputs.home-manager.nixosModules.home-manager
            inputs.nix-index-database.nixosModules.nix-index
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
          pkgs = import inputs.nixpkgs {
            system = hostSystem;
            inherit overlays;
          };
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
