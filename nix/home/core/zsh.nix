{
  lib,
  pkgs,
  osConfig,
  ...
}:
{
  home.packages =
    # Only add zsh for standalone HM, NixOS provides it system-wide.
    lib.optionals (osConfig == null) [ pkgs.zsh ]
    ++ (with pkgs; [
      bat
      fastfetch
      fzf
      starship
      zoxide
    ]);
}
