{
  config,
  lib,
  pkgs,
  ...
}:
let
  primaryUser = config.dandyrow.primaryUser;
in
{
  dandyrow.isWork = true;
  wsl = {
    enable = true;
    defaultUser = primaryUser;

    # Enable systemd under WSL2 (requires Windows 11 / WSL 0.67.6+).
    useWindowsDriver = true;
  };

  # WSL provides its own boot path; conflicts with common/systemd-boot.nix.
  systemd-boot.enable = false;

  # Corporate CA cert, manually placed at /etc/nixos/corp.pem (never committed).
  # Requires --impure; evaluates to [] when absent.
  security.pki.certificateFiles = lib.optionals (builtins.pathExists /etc/nixos/corp.pem) [
    /etc/nixos/corp.pem
  ];

  # Required to allow build verification of other systems which aren't behind corp
  # on this system
  systemd.services.nix-daemon.environment.NIX_SSL_CERT_FILE =
    lib.mkIf (builtins.pathExists /etc/nixos/corp.pem) "/etc/ssl/certs/ca-certificates.crt";

  users.users.${primaryUser}.extraGroups = [ "docker" ];

  # Runs VS Code Server's dynamically-linked node; its generic-linux build needs the stub loader.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      lz4
      xxhash
      zlib
      zstd
    ];
  };

  systemd.services.sbx-daemon = {
    description = "Docker Sandboxes daemon (sbx)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = primaryUser;
      ExecStart = "${pkgs.docker-sbx}/bin/sbx daemon start";
      ExecStop = "${pkgs.docker-sbx}/bin/sbx daemon stop";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  environment.systemPackages = [ pkgs.docker-sbx ];

  virtualisation.docker.enable = true;

  # Coincides with the other hosts by install date, not by sharing — do not consolidate.
  system.stateVersion = "25.11";
}
