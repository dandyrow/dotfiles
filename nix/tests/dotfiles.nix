{ lib }:
let
  configLinksWith =
    { hasDesktop }:
    (lib.evalModules {
      modules = [
        ../home/desktop.nix
        ../home/dotfiles.nix
        { dandyrow.hasDesktop = hasDesktop; }
        # Read the pure list without declaring the full HM `home.file` surface.
        { _module.check = false; }
        { _module.args.pkgs = { }; }
      ];
      specialArgs = {
        osConfig = null;
      };
    }).config.dandyrow.dotfiles.configLinks;
in
lib.runTests {
  # Terminal-agnostic tools are stowed on every host.
  testAlwaysStowsNvim = {
    expr = lib.elem "nvim" (configLinksWith {
      hasDesktop = false;
    });
    expected = true;
  };

  testKittyStowedOnDesktop = {
    expr = lib.elem "kitty" (configLinksWith {
      hasDesktop = true;
    });
    expected = true;
  };

  # A headless host must not receive the desktop terminal's config.
  testKittyAbsentWhenHeadless = {
    expr = lib.elem "kitty" (configLinksWith {
      hasDesktop = false;
    });
    expected = false;
  };
}
