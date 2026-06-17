{ pkgs, ... }:
{
  documentation.nixos.enable = false;

  programs = {
    git.enable = true;
    steam.enable = true;
  };

  environment.systemPackages = with pkgs; [
    bottles
  ];

  users.users = {
    dandyrow = {
      extraGroups = [
        "networkmanager"
        "print"
      ];

      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsxeHA5DWcz/L4A1BpozhL/BTNepsGXfrINkfeZSmvJ dandyrow@WSL" # Work Nix WSL
      ];
    };
  };

  system.stateVersion = "25.11";
}
