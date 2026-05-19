{ lib, ... }:
{
  documentation.nixos.enable = false;

  programs = {
    command-not-found.enable = true;
    firefox.enable = true;
    git.enable = true;
    starship.enable = true;
    neovim.enable = true;
    steam.enable = true;
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
    ];

  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIForH9TNaNvQGNBzWXyPdtRGO5xiR2BYQeIKf8mzN2u9 dandyrow@Desktop"
      ];
    };

    dandyrow.extraGroups = [
      "networkmanager"
      "print"
    ];
  };

  system.stateVersion = "24.05";
}
