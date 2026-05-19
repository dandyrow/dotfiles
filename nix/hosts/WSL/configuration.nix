{ ... }:
{
  wsl = {
    enable = true;
    defaultUser = "dandyrow";

    # Enable systemd under WSL2 (requires Windows 11 / WSL 0.67.6+)
    # See: https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/
    useWindowsDriver = true;

    docker-desktop.enable = true;
  };

  documentation.nixos.enable = false;

  programs.git.enable = true;

  system.stateVersion = "25.11";
}
