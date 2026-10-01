{ lib }:
let
  # Attr paths rather than values, so coverage stays assertable without evaluating a host.
  attrPathsFor =
    configurations: subPath: map (name: [ name ] ++ subPath) (lib.attrNames configurations);
in
{
  forcedAttrPaths = homeConfigurations: nixosConfigurations: {
    homeConfigurations = attrPathsFor homeConfigurations [
      "config"
      "home"
      "activationPackage"
      "drvPath"
    ];
    nixosConfigurations = attrPathsFor nixosConfigurations [
      "config"
      "system"
      "build"
      "toplevel"
      "drvPath"
    ];
  };
}
