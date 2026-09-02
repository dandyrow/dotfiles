{
  lib,
  pkgs,
  ...
}:
let
  herdrNavigator = pkgs.herdr-navigator;
  herdrAutomaticRename = pkgs.herdr-automatic-rename;
in
{
  # jq is called by the automatic-rename shell hook at runtime.
  # The plugin derivations are not in home.packages: both expose herdr-plugin.toml
  # at the store root, and buildEnv would conflict on that subpath. They're kept
  # alive via the activation and home.file references below.
  home.packages = [ pkgs.jq ];

  # herdr rewrites plugins.json, so a home.file write would be clobbered; re-link on activation.
  home.activation.linkHerdrPlugins = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    ${pkgs.herdr}/bin/herdr plugin link "${herdrNavigator}" >/dev/null 2>&1 || true
    ${pkgs.herdr}/bin/herdr plugin link "${herdrAutomaticRename}" >/dev/null 2>&1 || true
  '';

  # Stable path for .zshrc to source; the store path changes each rebuild.
  home.file.".config/herdr-automatic-rename/hook.zsh".text = ''
    source "${herdrAutomaticRename}/shell/hook.zsh"
  '';
}
