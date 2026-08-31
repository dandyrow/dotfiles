{ lib }:
let
  factsWith =
    {
      specialArgs,
      overrides ? { },
    }:
    (lib.evalModules {
      modules = [
        ../home/facts.nix
        { dandyrow = overrides; }
      ];
      inherit specialArgs;
    }).config.dandyrow;
in
lib.runTests {
  testOsConfigNullIsStandalone = {
    expr = (factsWith { specialArgs.osConfig = null; }).isStandalone;
    expected = true;
  };

  testOsConfigPresentIsNotStandalone = {
    expr = (factsWith { specialArgs.osConfig = { }; }).isStandalone;
    expected = false;
  };

  testGnomeEnabledIsDesktop = {
    expr =
      (factsWith {
        specialArgs.osConfig = {
          gnome.enable = true;
        };
      }).hasDesktop;
    expected = true;
  };

  testGnomeDisabledIsNotDesktop = {
    expr =
      (factsWith {
        specialArgs.osConfig = {
          gnome.enable = false;
        };
      }).hasDesktop;
    expected = false;
  };

  # NixOS hosts that never import the GNOME module have no `gnome` attr at all.
  testMissingGnomeAttrIsNotDesktop = {
    expr = (factsWith { specialArgs.osConfig = { }; }).hasDesktop;
    expected = false;
  };

  testStandaloneIsNotDesktop = {
    expr = (factsWith { specialArgs.osConfig = null; }).hasDesktop;
    expected = false;
  };

  testExplicitOverrideWins = {
    expr =
      (factsWith {
        specialArgs.osConfig = null;
        overrides.hasDesktop = true;
      }).hasDesktop;
    expected = true;
  };
}
