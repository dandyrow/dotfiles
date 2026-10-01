# Home configs never import the NixOS modules and host builds skip the standalone ones, so nothing else forces these to evaluate.
{
  lib,
  homeConfigurations,
  nixosConfigurations,
}:
let
  force = (import ../lib/config-eval.nix { inherit lib; }).force;
in
builtins.seq (force homeConfigurations nixosConfigurations) [ ]
