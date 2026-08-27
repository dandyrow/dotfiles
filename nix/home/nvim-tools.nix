{
  lib,
  pkgs,
  ...
}:
let
  nvimToolPackages = (import ../lib/nvim-tools.nix { inherit lib; }).nvimToolPackages;

  nvimToolsJson = builtins.fromJSON (builtins.readFile ../../nvim/.config/nvim/lua/config/tools.json);
in
{
  home.packages = nvimToolPackages nvimToolsJson pkgs;
}
