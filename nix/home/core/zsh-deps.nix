{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    bat
    fastfetch
    fzf
    starship
    zoxide
  ];
}
