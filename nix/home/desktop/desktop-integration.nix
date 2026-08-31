{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.dandyrow.hasDesktop {
  home.packages = [ pkgs.kitty ];
}
