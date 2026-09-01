{
  config,
  lib,
  pkgs,
  mattPocockSkills,
  ...
}:
let
  coreTools = with pkgs; [
    btop
    eza
    tmux
    herdr
    yazi
    opencode
  ];
in
{
  imports = [
    ./facts.nix
    ./core
    ./desktop
  ];

  config = {
    # NixOS feeds these from the user account, so only inject them standalone.
    home = lib.mkMerge [
      (lib.mkIf config.dandyrow.isStandalone {
        username = config.dandyrow.primaryUser;
        homeDirectory = "/home/${config.dandyrow.primaryUser}";
      })
      {
        stateVersion = "25.11";
        packages = coreTools;
      }
    ];

    xdg.dataFile."agents/skills/mattpocock".source = "${mattPocockSkills}/skills";

    # Move nix profile paths into XDG state directory.
    nix.assumeXdg = true;
  };
}
