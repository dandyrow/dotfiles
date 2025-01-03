{...}: {
  imports = [
    ./desktop/default.nix
    ./shell/default.nix
    ./systemd-boot.nix
    ./locale.nix
    ./gnupg.nix
  ];
}
