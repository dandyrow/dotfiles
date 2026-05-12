{ ... }:
{
  imports = [
    ./dotfiles.nix
    ./locale.nix
    ./systemd-boot.nix
    ./ssh.nix
    ./users.nix
    ./doas.nix
    ./gnupg.nix
    ./zsh.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
