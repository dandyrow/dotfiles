{
  lib,
  pkgs,
}:
let
  canvasKit = pkgs.callPackage ../pkgs/canvas-kit-mcp.nix { };
in
pkgs.runCommand "test-mcp-servers" { nativeBuildInputs = [ pkgs.nodejs ]; } ''
  node ${../../scripts/tests/mcp-smoke.mjs} ${canvasKit}/bin/canvas-kit-mcp
  touch "$out"
''
