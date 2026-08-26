{ lib, pkgs }:
let
  inherit (import ./nvim-tools-helpers.nix { inherit lib; })
    filterMasonOnly
    resolveNixpkgsAttrs
    ;
in
lib.runTests {
  testMasonOnlyExcluded = {
    expr = filterMasonOnly [
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
    ];
    expected = [
      "lua-language-server"
      "stylua"
    ];
  };

  testDeduplication = {
    expr = filterMasonOnly [
      {
        name = "rust-analyzer";
        nixpkgsAttr = "rust-analyzer";
      }
      {
        name = "rust-analyzer-copy";
        nixpkgsAttr = "rust-analyzer";
      }
    ];
    expected = [ "rust-analyzer" ];
  };

  testDottedAttrPathResolves = {
    expr = resolveNixpkgsAttrs pkgs [ "python3Packages.requests" ];
    expected = [ pkgs.python3Packages.requests ];
  };
}
