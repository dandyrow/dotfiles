{ lib }:
let
  profileWith =
    {
      specialArgs,
      overrides ? { },
    }:
    (lib.evalModules {
      modules = [
        ../home/profile.nix
        { dandyrow = overrides; }
      ];
      inherit specialArgs;
    }).config.dandyrow;
in
lib.runTests {
  testOsConfigNullIsStandalone = {
    expr = (profileWith { specialArgs.osConfig = null; }).isStandalone;
    expected = true;
  };

  testOsConfigPresentIsNotStandalone = {
    expr = (profileWith { specialArgs.osConfig = { }; }).isStandalone;
    expected = false;
  };

  testGnomeEnabledIsDesktop = {
    expr =
      (profileWith {
        specialArgs.osConfig = {
          gnome.enable = true;
        };
      }).hasDesktop;
    expected = true;
  };

  testGnomeDisabledIsNotDesktop = {
    expr =
      (profileWith {
        specialArgs.osConfig = {
          gnome.enable = false;
        };
      }).hasDesktop;
    expected = false;
  };

  # NixOS hosts that never import the GNOME module have no `gnome` attr at all.
  testMissingGnomeAttrIsNotDesktop = {
    expr = (profileWith { specialArgs.osConfig = { }; }).hasDesktop;
    expected = false;
  };

  # Standalone Home Manager has no osConfig, so it can never be a desktop by derivation.
  testStandaloneIsNotDesktop = {
    expr = (profileWith { specialArgs.osConfig = null; }).hasDesktop;
    expected = false;
  };

  testExplicitOverrideWins = {
    expr =
      (profileWith {
        specialArgs.osConfig = null;
        overrides.hasDesktop = true;
      }).hasDesktop;
    expected = true;
  };
}
