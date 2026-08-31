{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    # Only add zsh for standalone HM, NixOS provides it system-wide.
    lib.optionals config.dandyrow.isStandalone [ pkgs.zsh ]
    ++ (with pkgs; [
      bat
      fastfetch
      fzf
      starship
      zoxide
    ]);
}
