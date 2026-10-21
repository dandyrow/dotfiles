{ lib }:
let
  dotfilesDir = "/home/dandyrow/.dotfiles";

  # Raw targets, not the store derivations the real constructor would emit.
  declared =
    (import ../home/core/dotfiles-linking.nix {
      config = {
        lib.file.mkOutOfStoreSymlink = p: p;
        home.homeDirectory = "/home/dandyrow";
        dandyrow.isWork = true;
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
  copilotConfigsExist =
    builtins.pathExists (repoRoot + "/copilot/.config/copilot/mcp-config.json")
    && builtins.pathExists (repoRoot + "/copilot/.config/copilot-work/mcp-config.json");
in
lib.runTests {
  # A dead symlink is invisible until activation, so fail here instead.
  testAllConfigLinkTargetsExist = {
    expr = missing;
    expected = [ ];
  };
  testPersonalAndWorkCopilotConfigsExist = {
    expr = copilotConfigsExist;
    expected = true;
  };
}
