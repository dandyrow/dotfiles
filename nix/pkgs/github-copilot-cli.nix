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
      hash = "sha256-z70Rb+FZviiaut8sK/GKJairCe7KVKCR1AJeHLzaRwk=";
    };
    aarch64-linux = {
      suffix = "linux-arm64";
      hash = "sha256-saIHbLOlh+uivG9HjONeU/IKNNDWm0GAdDmzMC3191o=";
    };
    x86_64-darwin = {
      suffix = "darwin-x64";
      hash = "sha256-biISO2sXX+HWeGo+4vXRu3M9BN839sFBN0McAcPBWNI=";
    };
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-Tr+isxFUmWQgQX3ivglJ7x9ONa8JQ9ZVFUdNWuPCKxE=";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "github-copilot-cli: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "github-copilot-cli";
  version = "1.0.70";

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

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"/lib/github-copilot-cli
    cp -r * "$out"/lib/github-copilot-cli
    runHook postInstall
  '';

  postInstall = ''
    # No SSL_CERT_DIR/SSL_CERT_FILE pin: the bundled Rust (rustls) runtime falls
    # back to the system trust store, so custom/corporate CAs are honoured.
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
