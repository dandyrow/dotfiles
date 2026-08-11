{ lib, pkgs }:
let
  # runTests returns [] on success; surface any failures as an eval error so `nix flake check` reports them.
  mkTest =
    name: failures:
    if failures == [ ] then
      pkgs.runCommand "test-${name}" { } "touch $out"
    else
      throw "test-${name} failed:\n${lib.generators.toPretty { } failures}";
in
{
  has-desktop = mkTest "has-desktop" (import ./has-desktop.nix { inherit lib; });
}
