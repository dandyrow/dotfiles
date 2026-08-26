{
  lib,
  pkgs,
  ...
}:
let
  inherit (import ./nvim-tools-helpers.nix { inherit lib; })
    filterMasonOnly
    resolveNixpkgsAttrs
    ;

  nvimToolsJson = builtins.fromJSON (builtins.readFile ../../nvim/.config/nvim/lua/config/tools.json);
  nvimToolPackages = resolveNixpkgsAttrs pkgs (filterMasonOnly nvimToolsJson);
in
{
  home.packages = nvimToolPackages;
}
