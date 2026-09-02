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
  # Plugin paths collide on herdr-plugin.toml in buildEnv, so link via path, not packages.
  home.packages = [
    pkgs.herdr
    pkgs.jq
  ];

  # Re-link after linkGeneration so plugins.json survives the symlink/orphan cleanup.
  home.activation.linkHerdrPlugins = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${pkgs.herdr}/bin/herdr plugin link "${herdrNavigator}" || echo "herdr: failed to link herdr-navigator" >&2
    ${pkgs.herdr}/bin/herdr plugin link "${herdrAutomaticRename}" || echo "herdr: failed to link herdr-automatic-rename" >&2
  '';

  # Stable path for .zshrc to source; the store path changes each rebuild.
  home.file.".config/herdr-automatic-rename/hook.zsh".text = ''
    source "${herdrAutomaticRename}/shell/hook.zsh"
  '';

  # Read by automatic-rename.sh; TAB_CONTEXT=0 names tabs by program only.
  home.file.".config/herdr-automatic-rename/config.sh".text = ''
    TAB_CONTEXT=0
  '';
}
