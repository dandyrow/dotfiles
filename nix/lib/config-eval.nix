{ lib }:
let
  # Paths, not values: coverage stays assertable without evaluating a host.
  pathsByConfig = configurations: subPath: lib.genAttrs (lib.attrNames configurations) (_: subPath);

  forcedAttrPaths = homeConfigurations: nixosConfigurations: {
    homeConfigurations = pathsByConfig homeConfigurations [
      "config"
      "home"
      "activationPackage"
      "drvPath"
    ];
    nixosConfigurations = pathsByConfig nixosConfigurations [
      "config"
      "system"
      "build"
      "toplevel"
      "drvPath"
    ];
  };

  forceNamespace =
    paths: configurations:
    lib.mapAttrsToList (name: path: lib.getAttrFromPath path configurations.${name}) paths;
in
{
  inherit forcedAttrPaths;

  force =
    homeConfigurations: nixosConfigurations:
    let
      paths = forcedAttrPaths homeConfigurations nixosConfigurations;
    in
    builtins.deepSeq (
      forceNamespace paths.homeConfigurations homeConfigurations
      ++ forceNamespace paths.nixosConfigurations nixosConfigurations
    ) true;
}
