{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  patchelf,
  e2fsprogs,
  lz4,
  xxhash,
  zlib,
  zstd,
}:

let
  version = "0.30.0";
  sharedLibs = lib.makeLibraryPath [
    stdenv.cc.cc.lib
    lz4
    xxhash
    zlib
    zstd
  ];
in
stdenv.mkDerivation {
  pname = "docker-sbx";
  inherit version;

  src = fetchzip {
    url = "https://github.com/docker/sbx-releases/releases/download/v${version}/DockerSandboxes-linux.tar.gz";
    hash = "sha256-uO4HM+iCm4OHe727y0PVzzhV77LP7UG4MuCX6Tn9hBU=";
    stripRoot = true;
  };

  nativeBuildInputs = [
    makeWrapper
    patchelf
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/libexec/lib" "$out/share/doc/docker-sbx"

    install -m755 "$src/sbx"                             "$out/bin/sbx"
    install -m755 "$src/containerd-shim-nerdbox-v1"      "$out/libexec/containerd-shim-nerdbox-v1"
    install -m755 "$src/mkfs.erofs"                      "$out/libexec/mkfs.erofs"
    install -m755 "$src/libsailor.so"                    "$out/libexec/lib/libsailor.so"
    install -m644 "$src"/nerdbox-kernel-*                "$out/libexec/"
    install -m644 "$src"/nerdbox-initrd-*                "$out/libexec/"

    if [ -f "$src/LICENSE" ]; then
      install -m644 "$src/LICENSE" "$out/share/doc/docker-sbx/LICENSE"
    fi
    if [ -f "$src/THIRD-PARTY-NOTICES" ]; then
      install -m644 "$src/THIRD-PARTY-NOTICES" "$out/share/doc/docker-sbx/THIRD-PARTY-NOTICES"
    fi
    if [ -f "$src/apparmor-profile" ]; then
      install -m644 "$src/apparmor-profile" "$out/libexec/apparmor-profile"
    fi

    # Both executables were built for a generic Linux environment and carry
    # /lib64/ld-linux-x86-64.so.2 as their ELF interpreter.  On NixOS that
    # path is a stub that prints "cannot run dynamically linked executable",
    # so we must patch the interpreter to the Nix-store glibc loader as well
    # as the rpath for shared-library resolution.
    local interp
    interp="$(cat "${stdenv.cc}/nix-support/dynamic-linker")"

    patchelf \
      --set-interpreter "$interp" \
      --set-rpath "${sharedLibs}" \
      "$out/libexec/mkfs.erofs"
    patchelf \
      --set-interpreter "$interp" \
      --set-rpath "${sharedLibs}" \
      "$out/libexec/containerd-shim-nerdbox-v1"
    # libsailor.so is a shared library (no interpreter needed); extend its
    # rpath so it can resolve its own bundled dependencies.
    patchelf --set-rpath "${sharedLibs}:$out/libexec/lib" "$out/libexec/lib/libsailor.so"

    # $out/libexec must be on PATH so sandboxd can find mkfs.erofs and
    # containerd-shim-nerdbox-v1 at runtime; without it the erofs differ
    # plugin fails with exit status 127 and the entire daemon fails to start.
    wrapProgram "$out/bin/sbx" \
      --set LIBKRUN_PATH "$out/libexec" \
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
