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

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Move ~/.nix-defexpr and ~/.nix-profile to XDG state directories.
    use-xdg-base-directories = true;
  };
}
