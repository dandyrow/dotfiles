{
  lib,
  pkgs,
  nixosConfigurations,
  homeConfigurations,
}:
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
  profile = mkTest "profile" (import ./profile.nix { inherit lib; });
  clone-dotfiles = mkTest "clone-dotfiles" (import ./clone-dotfiles.nix { inherit lib; });
  nvim-tools = mkTest "nvim-tools" (import ./nvim-tools.nix { inherit lib pkgs; });
  undeclared-groups = mkTest "undeclared-groups" (
    import ./undeclared-groups.nix { inherit lib nixosConfigurations; }
  );
  config-eval = mkTest "config-eval" (
    import ./config-eval.nix { inherit lib homeConfigurations nixosConfigurations; }
  );
}
