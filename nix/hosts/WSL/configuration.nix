{ lib, pkgs, ... }:
{
  wsl = {
    enable = true;
    defaultUser = "dandyrow";

    # Enable systemd under WSL2 (requires Windows 11 / WSL 0.67.6+)
    # See: https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/
    useWindowsDriver = true;
  };

  # Disable systemd-boot — WSL provides its own boot path and the nixos-wsl
  # module sets installBootLoader to a no-op, which conflicts with the
  # systemd-boot module enabled by default in common/systemd-boot.nix.
  systemd-boot.enable = false;

  documentation.nixos.enable = false;

  programs.git.enable = true;

  # wslu provides wslview, which forwards URLs to the Windows host browser.
  # Required for tools like gh auth login that attempt to open a web browser.
  environment.systemPackages = [ pkgs.wslu ];

  # Include the corporate CA certificate if present at /etc/nixos/corp.pem.
  # This file must be placed there manually and is never committed to git.
  # Requires --impure flag when running nixos-rebuild.
  # The builtins.pathExists guard means this evaluates safely to [] when the
  # file is absent (e.g. on non-WSL machines without the cert).
  security.pki.certificateFiles = lib.optionals (builtins.pathExists /etc/nixos/corp.pem) [
    /etc/nixos/corp.pem
  ];

  system.stateVersion = "25.11";
}
