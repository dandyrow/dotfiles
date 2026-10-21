{ lib }:
let
  dotfilesDir = "/home/dandyrow/.dotfiles";

  # Raw targets, not the store derivations the real constructor would emit.
  declared =
    (import ../home/core/dotfiles-linking.nix {
      config = {
        lib.file.mkOutOfStoreSymlink = p: p;
        home.homeDirectory = "/home/dandyrow";
      };
      pkgs = { };
      lib.mkMerge = x: x;
    }).home.file;

  repoRoot = toString ../..;

  targets = lib.flatten (
    map (section: lib.attrValues (lib.mapAttrs (_: v: v.source) section)) declared
  );

  missing = lib.filter (t: !builtins.pathExists (repoRoot + "/" + t)) (
    map (lib.removePrefix (dotfilesDir + "/")) targets
  );
in
lib.runTests {
  # A dead symlink is invisible until activation, so fail here instead.
  testAllConfigLinkTargetsExist = {
    expr = missing;
    expected = [ ];
  };
}
