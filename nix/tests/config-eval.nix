# NixOS host builds never evaluate the standalone home configs (their clone step is gated on osConfig == null), so force those and the NixOS clone scripts to evaluate here instead.
{
  lib,
  homeConfigurations,
  nixosConfigurations,
}:
let
  allActivations =
    (map (hc: hc.config.home.activationPackage.drvPath) (lib.attrValues homeConfigurations))
    ++ (map (sys: sys.config.system.activationScripts.cloneDotfiles.text) (
      lib.attrValues nixosConfigurations
    ));
in
builtins.seq (builtins.toJSON allActivations) [ ]
