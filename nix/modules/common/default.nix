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
    ./agents.nix
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Move ~/.nix-defexpr and ~/.nix-profile to XDG state directories.
    use-xdg-base-directories = true;
  };

  # Disable legacy channel support — the system is fully flake-based.
  # This prevents the 'nix-channel' tooling and associated NIX_PATH entry
  # (/nix/var/nix/profiles/per-user/root/channels) from being set up,
  # eliminating the warning about that path not existing during nixos-rebuild.
  nix.channel.enable = false;

  programs.git = {
    enable = true;
    config = [ { safe.directory = "/home/dandyrow/.dotfiles"; } ];
  };
}
