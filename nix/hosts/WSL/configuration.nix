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

  # Enable nix-ld so the docker-sbx containerd shim (a Go cgo binary) and
  # mkfs.erofs can resolve /lib64/ld-linux-x86-64.so.2 at runtime.  This
  # replaces a previous attempt to patchelf --set-interpreter on the shim,
  # which corrupts Go binaries: extending PT_INTERP shifts PT_LOAD offsets
  # and Go's runtime hard-codes layout assumptions, causing SIGSEGV at the
  # entry point.  nix-ld is the canonical NixOS way to run unmodified
  # foreign Linux binaries.
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

  # sbx daemon as a user-scoped system service.  No CAP_SYS_ADMIN and no
  # disk group: verified against a working Ubuntu/WSL2 install (sbx 0.30.0)
  # where the daemon runs with CapEff=0 and is not in the disk group, so
  # the mount/loop operations needed by sbx do not require either.
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

  system.stateVersion = "25.11";
}
