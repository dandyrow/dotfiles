{ lib }:
let
  hasDesktopWith =
    {
      specialArgs,
      overrides ? { },
    }:
    (lib.evalModules {
      modules = [
        ../home/desktop.nix
        { dandyrow = overrides; }
      ];
      inherit specialArgs;
    }).config.dandyrow.hasDesktop;
in
lib.runTests {
  testGnomeEnabledIsDesktop = {
    expr = hasDesktopWith {
      specialArgs.osConfig = {
        gnome.enable = true;
      };
    };
    expected = true;
  };

  testGnomeDisabledIsNotDesktop = {
    expr = hasDesktopWith {
      specialArgs.osConfig = {
        gnome.enable = false;
      };
    };
    expected = false;
  };

  # NixOS hosts that never import the GNOME module have no `gnome` attr at all.
  testMissingGnomeAttrIsNotDesktop = {
    expr = hasDesktopWith { specialArgs.osConfig = { }; };
    expected = false;
  };

  # Home Manager always supplies osConfig, defaulting it to null off NixOS.
  testNullOsConfigIsNotDesktop = {
    expr = hasDesktopWith { specialArgs.osConfig = null; };
    expected = false;
  };

  testExplicitOverrideWins = {
    expr = hasDesktopWith {
      specialArgs.osConfig = null;
      overrides.hasDesktop = true;
    };
    expected = true;
  };
}
