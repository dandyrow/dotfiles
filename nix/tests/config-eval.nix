# flake.cc force-evaluates nixosConfigurations but treats homeConfigurations as unchecked, so nothing else forces these.
{
  lib,
  homeConfigurations,
}:
let
  allActivations = map (hc: hc.config.home.activationPackage.drvPath) (
    lib.attrValues homeConfigurations
  );
in
builtins.seq (builtins.toJSON allActivations) [ ]
