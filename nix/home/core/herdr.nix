{
  lib,
  pkgs,
  ...
}:
let
  herdrNavigator = pkgs.herdr-navigator;
in
{
  home.packages = [
    herdrNavigator
  ];

  # herdr rewrites plugins.json, so a home.file write would be clobbered; re-link on activation.
  home.activation.linkHerdrNavigator = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    ${pkgs.herdr}/bin/herdr plugin link "${herdrNavigator}" >/dev/null 2>&1 || true
  '';
}
