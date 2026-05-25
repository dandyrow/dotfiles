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

  # Libraries dlopened/linked by the upstream binaries (mainly erofs
  # compression deps). Added defensively so an upstream bump can't silently
  # break runtime resolution.
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

  # Prebuilt Go binaries: stripping can invalidate embedded build info.
  dontStrip = true;

  # Disable stdenv's `patchelf --shrink-rpath` fixup. It drops rpath entries
  # whose dir holds no DT_NEEDED library; libsailor.so is dlopened (cgo), so
  # the shrink would remove the very entries we add below.
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

    # mkfs.erofs and containerd-shim-nerdbox-v1 hardcode the glibc loader at
    # /lib64/ld-linux-x86-64.so.2, which is a NixOS stub that exits 127. The
    # daemon then skips the erofs differ, cascading into transfer-plugin
    # registration failure. Patch interpreter + rpath together so they stay
    # in sync on every version bump.
    interp=${stdenv.cc.bintools.dynamicLinker}

    patchelf \
      --set-interpreter "$interp" \
      --set-rpath "${sharedLibs}" \
      "$out/libexec/mkfs.erofs"

    # Shim dlopens libsailor.so via cgo (sailor_config_*, sailor_vm_*); add
    # libexec/lib to its rpath so resolution doesn't need LD_LIBRARY_PATH.
    patchelf \
      --set-interpreter "$interp" \
      --set-rpath "${sharedLibs}:$out/libexec/lib" \
      "$out/libexec/containerd-shim-nerdbox-v1"

    # libsailor.so: shared lib, no interpreter. Extend rpath for neighbours.
    patchelf \
      --set-rpath "${sharedLibs}:$out/libexec/lib" \
      "$out/libexec/lib/libsailor.so"

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
