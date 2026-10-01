# Guards the flake check's blast radius: a host or home config nobody forces to evaluate is one that can rot unnoticed.
{
  lib,
  homeConfigurations,
  nixosConfigurations,
}:
let
  coverage = import ../lib/config-eval.nix { inherit lib; };

  forced = coverage.forcedAttrPaths homeConfigurations nixosConfigurations;

  unforced = paths: names: lib.filter (name: !(lib.hasAttr name paths)) names;

  configuration = config: { inherit config; };
in
lib.runTests {
  # Poisoned fixtures prove the forcing reaches the value; the coverage assertions below cannot.
  testHostToplevelIsForced = {
    expr =
      (builtins.tryEval (
        coverage.force { } {
          BrokenHost = configuration { system.build.toplevel.drvPath = throw "unforced"; };
        }
      )).success;
    expected = false;
  };

  testHomeActivationPackageIsForced = {
    expr =
      (builtins.tryEval (
        coverage.force {
          BrokenHome = configuration { home.activationPackage.drvPath = throw "unforced"; };
        } { }
      )).success;
    expected = false;
  };

  # Without this the two above would pass just as happily against a force that always throws.
  testHealthyConfigurationsForce = {
    expr =
      (builtins.tryEval (
        coverage.force {
          TestHome = configuration { home.activationPackage.drvPath = "/nix/store/fake.drv"; };
        } { TestHost = configuration { system.build.toplevel.drvPath = "/nix/store/fake.drv"; }; }
      )).success;
    expected = true;
  };

  # Read off the flake's own host set, so a host added later needs no test edit.
  testEveryNixosHostIsForced = {
    expr = unforced forced.nixosConfigurations (builtins.attrNames nixosConfigurations);
    expected = [ ];
  };

  testEveryHomeConfigIsForced = {
    expr = unforced forced.homeConfigurations (builtins.attrNames homeConfigurations);
    expected = [ ];
  };

  # A hard-coded host list would go stale the moment a host is renamed or added.
  testCoverageIsNotHardCoded = {
    expr =
      builtins.attrNames
        (coverage.forcedAttrPaths { } { HostAddedLater = null; }).nixosConfigurations;
    expected = [ "HostAddedLater" ];
  };
}
