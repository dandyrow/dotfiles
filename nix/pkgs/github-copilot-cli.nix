{
  lib,
  stdenv,
  autoPatchelfHook,
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
let
  sources = {
    x86_64-linux = {
      suffix = "linux-x64";
      hash = "sha256-2s6jYMgj3Vj3ENeoHDa76fZ3PfRYkIeqJctmumN8gig=";
    };
    aarch64-linux = {
      suffix = "linux-arm64";
      hash = "sha256-TYgTS5IT+B9eMetc7noZH5FvVv9m4/s9Eh7sdspigJ4=";
    };
    x86_64-darwin = {
      suffix = "darwin-x64";
      hash = "sha256-mxqn3jGddO4eIglerqwyB6XNp42d8bzMM1AJfgSYWZg=";
    };
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-HR4GBZ0LrHONzMND3rqXzQvw0XV1TsKfg6Ckc6osa0A=";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "github-copilot-cli: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "github-copilot-cli";
  version = "1.0.80";

  src = fetchurl {
    url = "https://github.com/github/copilot-cli/releases/download/v${finalAttrs.version}/github-copilot-${finalAttrs.version}-${source.suffix}.tgz";
    inherit (source) hash;
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
  # Only the optional canvas-GUI webview prebuild wants these; terminal use never loads it.
  autoPatchelfIgnoreMissingDeps = [
    "libwebkit2gtk-4.1.so.0"
    "libgtk-3.so.0"
    "libgdk-3.so.0"
    "libcairo.so.2"
    "libgdk_pixbuf-2.0.so.0"
    "libsoup-3.0.so.0"
    "libjavascriptcoregtk-4.1.so.0"
    "libwayland-client.so.0"
    "libdbus-1.so.3"
    "libxdo.so.3"
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
