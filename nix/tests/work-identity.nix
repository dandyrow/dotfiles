{ lib }:
let
  homeFileOption = {
    options.home.file = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule { freeformType = lib.types.attrs; });
      default = { };
      description = "Declarative file bindings mirroring Home Manager's home.file.";
    };
  };
  workText =
    isWork:
    (lib.evalModules {
      modules = [
        ../home/core/work-identity.nix
        homeFileOption
        { dandyrow.isWork = isWork; }
      ];
    }).config.home.file."Projects/work/.gitconfig".text or null;
in
lib.runTests {
  testWorkIdentityAbsentWhenNotWorkHost = {
    expr = workText false;
    expected = null;
  };

  testWorkIdentityMatchesWorkEmailAndGpgOff = {
    expr = workText true;
    expected = ''
      [user]
        name = Daniel Lowry
        email = daniel.lowry@kainos.com

      [commit]
        gpgSign = false

      [tag]
        gpgSign = false
    '';
  };
}
