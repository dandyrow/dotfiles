{
  lib,
  stdenv,
  fetchFromGitHub,
}:

# Pure bash, so the store path IS the plugin: link it, don't install it.
stdenv.mkDerivation {
  pname = "herdr-automatic-rename";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "qu8n";
    repo = "herdr-automatic-rename";
    rev = "bd0dfc4bf8053df13ebb527f213a0e74d1420e2c";
    hash = "sha256-CZcGOFuLtsyVP55rfhh41kpowCcNbxj5XYWJZIcm8u0=";
  };

  patches = [ ../patches/herdr-automatic-rename-hook-path.patch ];

  dontBuild = true;
  installPhase = ''
    runHook preInstall
    cp -r . "$out"
    runHook postInstall
  '';

  meta = {
    description = "Herdr plugin to auto-name tabs after the foreground process with [N] jump numbers";
    homepage = "https://github.com/qu8n/herdr-automatic-rename";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
