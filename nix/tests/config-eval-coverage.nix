# Guards the flake check's blast radius: a host or home config nobody forces to evaluate is one that can rot unnoticed.
{
  lib,
  homeConfigurations,
  nixosConfigurations,
}:
let
  coverage = (import ../lib/config-eval.nix { inherit lib; }).forcedAttrPaths;

  forced = coverage homeConfigurations nixosConfigurations;

  forcedNames = paths: map lib.head paths;

  uncovered = paths: names: lib.filter (name: !(lib.elem name (forcedNames paths))) names;
in
lib.runTests {
  # Derived from the flake's own host set, so a host added later needs no test edit.
  testEveryNixosHostIsForced = {
    expr = uncovered forced.nixosConfigurations (builtins.attrNames nixosConfigurations);
    expected = [ ];
  };

  testEveryHomeConfigIsForced = {
    expr = uncovered forced.homeConfigurations (builtins.attrNames homeConfigurations);
    expected = [ ];
  };

  # A hard-coded host list would go stale the moment a host is renamed or added.
  testCoverageIsNotHardCoded = {
    expr = forcedNames (coverage { } { HostAddedLater = null; }).nixosConfigurations;
    expected = [ "HostAddedLater" ];
  };

  # Only forcing the toplevel derivation trips a failing NixOS `assertions` entry.
  testNixosForcesToplevelDerivation = {
    expr = lib.unique (map lib.tail forced.nixosConfigurations);
    expected = [
      [
        "config"
        "system"
        "build"
        "toplevel"
        "drvPath"
      ]
    ];
  };

  testHomeForcesActivationPackageDerivation = {
    expr = lib.unique (map lib.tail forced.homeConfigurations);
    expected = [
      [
        "config"
        "home"
        "activationPackage"
        "drvPath"
      ]
    ];
  };
}
