{
  config,
  lib,
  pkgs,
  ...
}:
let
  dotfilesDir = "${config.home.homeDirectory}/.dotfiles";
in
lib.mkIf config.dandyrow.hasDesktop {
  home.packages = [ pkgs.kitty ];

  # Points at the live clone of config, not the Nix store.
  home.file.".config/kitty".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/kitty/.config/kitty";
}
