# Force every deployment's activation to render — NixOS hosts keep the standalone branch lazy, masking broken adapter paths.
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
