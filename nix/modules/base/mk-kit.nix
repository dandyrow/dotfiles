{ pkgs }:
name: src:
pkgs.runCommand "sbx-kit-${name}.zip" { nativeBuildInputs = [ pkgs.zip ]; } ''
  cp -r ${src} ./kit
  chmod -R u+w ./kit
  (cd ./kit && zip -qr $out .)
''
