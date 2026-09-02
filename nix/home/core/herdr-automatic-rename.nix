{
  lib,
  pkgs,
  ...
}:
let
  plugin = pkgs.herdr-automatic-rename;
in
{
  # Both the plugin and its shell hooks call out to jq at runtime.
  home.packages = [
    plugin
    pkgs.jq
  ];

  # herdr rewrites plugins.json, so a home.file write would be clobbered; re-link on activation.
  home.activation.linkHerdrAutomaticRename = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    ${pkgs.herdr}/bin/herdr plugin link "${plugin}" >/dev/null 2>&1 || true
  '';

  # Stable path for .zshrc to source; the store path changes each rebuild.
  home.file.".config/herdr-automatic-rename/hook.zsh".text = ''
    source "${plugin}/shell/hook.zsh"
  '';
}
