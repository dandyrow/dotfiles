# Home configs never import the NixOS modules and host builds skip the standalone ones, so nothing else forces these to evaluate.
{
  lib,
  homeConfigurations,
  nixosConfigurations,
}:
let
  forced =
    (import ../lib/config-eval.nix { inherit lib; }).forcedAttrPaths homeConfigurations
      nixosConfigurations;

  force = paths: configurations: map (path: lib.getAttrFromPath path configurations) paths;
in
builtins.seq (builtins.toJSON (
  force forced.homeConfigurations homeConfigurations
  ++ force forced.nixosConfigurations nixosConfigurations
)) [ ]
