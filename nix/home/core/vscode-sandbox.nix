{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    bubblewrap
    socat
  ];
}
