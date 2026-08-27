{ lib, pkgs }:
let
  nvimToolPackages = (import ../lib/nvim-tools.nix { inherit lib; }).nvimToolPackages;
in
lib.runTests {
  testMasonOnlyExcluded = {
    expr = nvimToolPackages [
      {
        name = "lua-ls";
        nixpkgsAttr = "lua-language-server";
      }
      {
        name = "copilot";
        masonOnly = true;
      }
      {
        name = "stylua";
        nixpkgsAttr = "stylua";
      }
    ] pkgs;
    expected = [
      pkgs.lua-language-server
      pkgs.stylua
    ];
  };

  testDeduplication = {
    expr = nvimToolPackages [
      {
        name = "rust-analyzer";
        nixpkgsAttr = "rust-analyzer";
      }
      {
        name = "rust-analyzer-copy";
        nixpkgsAttr = "rust-analyzer";
      }
    ] pkgs;
    expected = [ pkgs.rust-analyzer ];
  };

  testDottedAttrPathResolves = {
    expr = nvimToolPackages [
      {
        name = "debugpy";
        nixpkgsAttr = "python3Packages.requests";
      }
    ] pkgs;
    expected = [ pkgs.python3Packages.requests ];
  };
}
