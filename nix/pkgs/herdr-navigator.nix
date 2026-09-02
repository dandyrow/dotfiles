{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation {
  pname = "herdr-navigator";
  version = "0.1.0-unstable-2026-09-02";

  src = fetchFromGitHub {
    owner = "kaar";
    repo = "nvim-herdr-navigator";
    rev = "3e6024f0e771085913e27f3582dfb073ed13638a";
    hash = "sha256-CaIANT16W3nsIKCDi9zo0mtbirWnwSoJGg+aHSPPt1Q=";
  };

  dontBuild = true;
  installPhase = ''
    runHook preInstall
    cp -r . "$out"
    chmod +x "$out/h-nav"
    runHook postInstall
  '';

  meta = {
    description = "Seamless ctrl+h/j/k/l across herdr panes and Neovim splits";
    homepage = "https://github.com/kaar/nvim-herdr-navigator";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
