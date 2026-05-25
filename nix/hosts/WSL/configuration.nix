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

  # Include the corporate CA certificate if present at /etc/nixos/corp.pem.
  # This file must be placed there manually and is never committed to git.
  # Requires --impure flag when running nixos-rebuild.
  # The builtins.pathExists guard means this evaluates safely to [] when the
  # file is absent (e.g. on non-WSL machines without the cert).
  security.pki.certificateFiles = lib.optionals (builtins.pathExists /etc/nixos/corp.pem) [
    /etc/nixos/corp.pem
  ];

  # WSL creates /dev/loop-control and /dev/loop* as root:disk 0660.  sbx needs
  # to open /dev/loop-control to mount its erofs sandbox image, and that DAC
  # check is not bypassed by CAP_SYS_ADMIN, so dandyrow must be in disk.
  users.users.dandyrow.extraGroups = [ "disk" ];

  # sbx (Docker Sandboxes) daemon requires CAP_SYS_ADMIN to call mount() for
  # erofs sandbox images.  A user service cannot self-elevate capabilities,
  # so we run a system-level service as dandyrow and grant CAP_SYS_ADMIN via
  # AmbientCapabilities so the capability is inherited by the daemon process.
  systemd.services.sbx-daemon = {
    description = "Docker Sandboxes daemon (sbx)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "dandyrow";
      ExecStart = "${pkgs.docker-sbx}/bin/sbx daemon start";
      ExecStop = "${pkgs.docker-sbx}/bin/sbx daemon stop";
      AmbientCapabilities = "CAP_SYS_ADMIN";
      CapabilityBoundingSet = "CAP_SYS_ADMIN";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  system.stateVersion = "25.11";
}
