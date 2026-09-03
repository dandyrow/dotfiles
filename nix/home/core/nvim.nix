{
  lib,
  pkgs,
  ...
}:
let
  nvimToolPackages = (import ../../lib/nvim-tools.nix { inherit lib; }).nvimToolPackages;

  nvimToolsJson = builtins.fromJSON (
    builtins.readFile ../../../nvim/.config/nvim/lua/config/tools.json
  );
in
{
  home.packages =
    (nvimToolPackages nvimToolsJson pkgs)
    ++ (with pkgs; [
      neovim
      fd
      gcc
      gh
      github-copilot-cli
      gnumake
      python3
      ripgrep
      tree-sitter
      unzip
      wl-clipboard
      nodejs
      wget
    ]);
}
