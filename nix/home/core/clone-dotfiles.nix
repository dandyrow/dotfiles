{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cloneDotfiles = import ../../lib/clone-dotfiles.nix { inherit lib; };
in
{
  # Standalone HM clones as the user; on NixOS the root adapter owns the clone.
  home.activation = lib.mkIf (osConfig == null) {
    cloneDotfiles = lib.hm.dag.entryBefore [ "linkGeneration" ] (cloneDotfiles {
      home = config.home.homeDirectory;
      git = "${pkgs.git}/bin/git";
    });
  };
}
