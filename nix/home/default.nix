{
  pkgs,
  mattPocockSkills,
  ...
}:
let
  coreTools = with pkgs; [
    btop
    eza
    tmux
    yazi
    opencode
  ];
in
{
  imports = [
    ./core
    ./desktop.nix
    ./desktop
  ];

  home = {
    stateVersion = "25.11";

    packages = coreTools;
  };

  xdg.dataFile."agents/skills/mattpocock".source = "${mattPocockSkills}/skills";

  # Move nix profile paths into XDG state directory.
  nix.assumeXdg = true;
}
