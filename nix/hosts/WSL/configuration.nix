{ lib, pkgs, ... }:
{
  wsl = {
    enable = true;
    defaultUser = "dandyrow";

    # Enable systemd under WSL2 (requires Windows 11 / WSL 0.67.6+).
    useWindowsDriver = true;
  };

  # WSL provides its own boot path; conflicts with common/systemd-boot.nix.
  systemd-boot.enable = false;

  documentation.nixos.enable = false;

  # Corporate CA cert, manually placed at /etc/nixos/corp.pem (never committed).
  # Requires --impure; evaluates to [] when absent.
  security.pki.certificateFiles = lib.optionals (builtins.pathExists /etc/nixos/corp.pem) [
    /etc/nixos/corp.pem
  ];

  # Lets docker-sbx's Go cgo shim and mkfs.erofs resolve /lib64/ld-linux at
  # runtime, avoiding patchelf (which corrupts Go binaries' PT_LOAD layout).
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

  # sbx daemon as a user-scoped system service. No CAP_SYS_ADMIN / disk group:
  # the working Ubuntu/WSL2 install runs sbx 0.30.0 without either.
  systemd.services.sbx-daemon = {
    description = "Docker Sandboxes daemon (sbx)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "dandyrow";
      ExecStart = "${pkgs.docker-sbx}/bin/sbx daemon start";
      ExecStop = "${pkgs.docker-sbx}/bin/sbx daemon stop";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  virtualisation.docker.enable = true;
  users.users.dandyrow.extraGroups = [ "docker" ];

  system.stateVersion = "25.11";
}
