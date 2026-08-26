{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkIf config.dandyrow.hasDesktop {
  home.packages = [ pkgs.kitty ];
}
