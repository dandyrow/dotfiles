{
  lib,
  pkgs,
  homeConfigurations,
  ciBuilds,
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
  facts = mkTest "facts" (import ./facts.nix { inherit lib; });
  clone-dotfiles = mkTest "clone-dotfiles" (import ./clone-dotfiles.nix { inherit lib; });
  dotfiles-linking = mkTest "dotfiles-linking" (import ./dotfiles-linking.nix { inherit lib; });
  nvim-tools = mkTest "nvim-tools" (import ./nvim-tools.nix { inherit lib pkgs; });
  work-identity = mkTest "work-identity" (import ./work-identity.nix { inherit lib; });
  config-eval = mkTest "config-eval" (import ./config-eval.nix { inherit lib homeConfigurations; });
  ci-builds = mkTest "ci-builds" (import ./ci-builds.nix { inherit lib ciBuilds; });
  worktree-scripts = import ./worktree-scripts.nix { inherit pkgs; };
}
