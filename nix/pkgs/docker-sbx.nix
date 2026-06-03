{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  e2fsprogs,
}:

let
  version = "0.30.0";
in
stdenv.mkDerivation {
  pname = "docker-sbx";
  inherit version;

  src = fetchzip {
    url = "https://github.com/docker/sbx-releases/releases/download/v${version}/DockerSandboxes-linux.tar.gz";
    hash = "sha256-uO4HM+iCm4OHe727y0PVzzhV77LP7UG4MuCX6Tn9hBU=";
    stripRoot = true;
  };

  nativeBuildInputs = [ makeWrapper ];

  # Prebuilt Go binaries: stripping can invalidate embedded build info.
  dontStrip = true;

  # patchelf'ing the Go cgo shim corrupts its PT_LOAD layout and segfaults
  # at entry; rely on programs.nix-ld on the host instead.
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/libexec/lib" "$out/share/doc/docker-sbx"

    # Layout mirrors upstream install.sh:
    #   bin/sbx, libexec/{shim,mkfs.erofs,nerdbox-*}, libexec/lib/libsailor.so
    install -m755 "$src/sbx"                        "$out/bin/sbx"
    install -m755 "$src/containerd-shim-nerdbox-v1" "$out/libexec/containerd-shim-nerdbox-v1"
    install -m755 "$src/mkfs.erofs"                 "$out/libexec/mkfs.erofs"
    install -m755 "$src/libsailor.so"               "$out/libexec/lib/libsailor.so"
    install -m644 "$src"/nerdbox-kernel-*           "$out/libexec/"
    install -m644 "$src"/nerdbox-initrd-*           "$out/libexec/"

    if [ -f "$src/LICENSE" ]; then
      install -m644 "$src/LICENSE" "$out/share/doc/docker-sbx/LICENSE"
    fi
    if [ -f "$src/THIRD-PARTY-NOTICES" ]; then
      install -m644 "$src/THIRD-PARTY-NOTICES" "$out/share/doc/docker-sbx/THIRD-PARTY-NOTICES"
    fi
    if [ -f "$src/apparmor-profile" ]; then
      install -m644 "$src/apparmor-profile" "$out/libexec/apparmor-profile"
    fi

    # sbx shells out to mkfs.erofs (bundled) and mkfs.ext4 (e2fsprogs); neither
    # is on the default NixOS PATH, so prepend both.
    wrapProgram "$out/bin/sbx" \
      --prefix PATH : "$out/libexec:${lib.makeBinPath [ e2fsprogs ]}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Docker Sandboxes CLI — safe microVM environments for AI agents";
    homepage = "https://github.com/docker/sbx-releases";
    license = licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    mainProgram = "sbx";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
