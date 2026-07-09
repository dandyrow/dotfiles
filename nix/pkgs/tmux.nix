{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  bison,
  libevent,
  ncurses,
  pkg-config,
  runCommand,
  withSystemd ? lib.meta.availableOn stdenv.hostPlatform systemdLibs,
  systemdLibs,
  # broken on i686-linux https://github.com/tmux/tmux/issues/4597
  withUtf8proc ? !(stdenv.hostPlatform.is32bit),
  utf8proc,
  withUtempter ? stdenv.hostPlatform.isLinux,
  libutempter,
  withSixel ? true,
}:

# Local override of nixpkgs' tmux to track git master past 3.7b.
# Picks up fixes for three DEC 2026 (MODE_SYNC) bugs in 3.7b:
#   - Structural commands not gated on MODE_SYNC (#4983)
#   - Mouse mode re-asserted outside sync brackets on every redraw (#5303)
#   - PR #5195 (nicm's patch in #4983 comment thread)
# These cause cursor flickering in TUI apps (e.g. opencode) that use
# \033[?2026h/l for synchronized output.
# Delete this file and the overlay entry in flake.nix once nixpkgs ships
# tmux 3.8 or a patched 3.7.x.
stdenv.mkDerivation (finalAttrs: {
  pname = "tmux";
  version = "3.7b-unstable-2026-07-09";

  outputs = [
    "out"
    "man"
  ];

  src = fetchFromGitHub {
    owner = "tmux";
    repo = "tmux";
    rev = "ec31f4566dca2315dee04c9c23834c0020a27b86";
    hash = "sha256-LUmiKa8D22unaNNIDpWYpi5XsJzo/wKY44Vjeh357Fc=";
  };

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    bison
  ];

  buildInputs = [
    ncurses
    libevent
  ]
  ++ lib.optionals withSystemd [ systemdLibs ]
  ++ lib.optionals withUtf8proc [ utf8proc ]
  ++ lib.optionals withUtempter [ libutempter ];

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ]
  ++ lib.optionals withSystemd [ "--enable-systemd" ]
  ++ lib.optionals withSixel [ "--enable-sixel" ]
  ++ lib.optionals withUtempter [ "--enable-utempter" ]
  ++ lib.optionals withUtf8proc [ "--enable-utf8proc" ];

  enableParallelBuilding = true;

  passthru.terminfo = runCommand "tmux-terminfo" { nativeBuildInputs = [ ncurses ]; } ''
    mkdir -p $out/share/terminfo/t
    ln -sv ${ncurses}/share/terminfo/t/{tmux,tmux-256color,tmux-direct} $out/share/terminfo/t
  '';

  meta = {
    homepage = "https://tmux.github.io/";
    description = "Terminal multiplexer";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
    mainProgram = "tmux";
  };
})
