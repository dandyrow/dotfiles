{
  description = "Controller environment for the Proxmox bootstrap playbook";

  # Track the root flake.lock's nixpkgs so the controller matches the machine's package set.
  inputs.nixpkgs.url = "https://releases.nixos.org/nixpkgs/nixpkgs-26.11pre1070934.1927682e0d80/nixexprs.tar.xz";

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "bws" ];
      };
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [
          pkgs.bws
          (pkgs.python3.withPackages (ps: [
            ps.ansible-core
            ps.proxmoxer
            ps.requests
          ]))
        ];
      };
    };
}
