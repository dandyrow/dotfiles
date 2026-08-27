{
  lib,
  homeConfigurations,
  nixosConfigurations,
}:
let
  # Render every activation path; NixOS hosts never force the standalone branch thanks to the osConfig guard.
  allActivations =
    (map (hc: hc.config.home.activationPackage.drvPath) (lib.attrValues homeConfigurations))
    ++ (map (sys: sys.config.system.activationScripts.cloneDotfiles.text) (
      lib.attrValues nixosConfigurations
    ));
in
builtins.seq (builtins.toJSON allActivations) [ ]
