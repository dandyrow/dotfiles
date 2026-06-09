{
  lib,
  stdenv,
  autoPatchelfHook,
  cacert,
  fetchurl,
  glib,
  libsecret,
  makeBinaryWrapper,
  bash,
  nodejs,
  versionCheckHook,
  nix-update-script,
}:

# Local override of nixpkgs' github-copilot-cli to track a newer upstream
# release than nixos-unstable currently ships. Delete this file (and the
# overlay entry in flake.nix) once nixpkgs catches up to this version or
# newer.
stdenv.mkDerivation (finalAttrs: {
  pname = "github-copilot-cli";
  version = "1.0.60";

  # GitHub provide platform-specific SEA binaries as well as a "universal"
  # package.  Use the universal package as it gives us a bit more flexibility
  # about how it's configured.  In particular, the SEA binary has fixed ideas
  # about how paths should be set up which don't reliably hold when using Nix.
  src = fetchurl {
    url = "https://github.com/github/copilot-cli/releases/download/v${finalAttrs.version}/github-copilot-${finalAttrs.version}.tgz";
    hash = "sha256-wUEBstKx8Yb9m6ynIi137ZXR7dO39uepnv/yGFVE/qQ=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    glib
    libsecret
  ];
  sourceRoot = "package";
  dontStrip = true;
  # computer.node requires GUI/media libraries (X11, pipewire, libei, libjpeg,
  # libpng) for screen-capture and input-simulation features that are not
  # relevant for CLI use; ignore those missing deps rather than fail the build
  # or pull in heavy dependencies.
  #
  # keytar ships musl-libc prebuilds (linuxmusl-{x64,arm64}) alongside the
  # glibc ones; the glibc build is what actually loads on NixOS, so ignore
  # libc.musl-x86_64.so.1 from the unused musl variants rather than try to
  # provide musl on a glibc system.
  autoPatchelfIgnoreMissingDeps = [
    "libX11.so.6"
    "libXtst.so.6"
    "libjpeg.so.8"
    "libpng16.so.16"
    "libpipewire-0.3.so.0"
    "libei.so.1"
    "libc.musl-x86_64.so.1"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"/lib/github-copilot-cli
    cp -r * "$out"/lib/github-copilot-cli
    runHook postInstall
  '';

  postInstall = ''
    makeWrapper ${nodejs}/bin/node "$out"/bin/copilot \
      --add-flag "$out"/lib/github-copilot-cli/index.js \
      --add-flag --no-auto-update \
      --set-default NODE_NO_WARNINGS 1 \
      --set-default SSL_CERT_DIR ${cacert}/etc/ssl/certs \
      --prefix PATH : "${lib.makeBinPath [ bash ]}"
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  # TODO are these errors still present after moving to using the "universal"
  # package?
  doInstallCheck = !stdenv.hostPlatform.isDarwin; # skip on Darwin - OpenSSL errors in sandbox

  # Looks like GitHub use tags for both pre-release and actually released
  # versions, but only the actual versions will be available as a GitHub
  # release, so use the release endpoint rather than nix-update-script`'s
  # default of looking for tags.
  passthru.updateScript = nix-update-script { extraArgs = [ "--use-github-releases" ]; };

  meta = {
    description = "GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal";
    homepage = "https://github.com/github/copilot-cli";
    changelog = "https://github.com/github/copilot-cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [
      dbreyfogle
      me-and
    ];
    mainProgram = "copilot";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
