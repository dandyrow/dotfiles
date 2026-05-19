{ ... }:
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

  system.stateVersion = "25.11";
}
