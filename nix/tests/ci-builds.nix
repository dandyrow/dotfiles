# An empty or shrunken ciBuilds still passes CI, so pin the entries it must have here.
{ lib, ciBuilds }:
let
  expected = [
    "github-copilot-cli"
    "herdr"
    "herdr-automatic-rename"
    "herdr-navigator"
    "nvidia-driver"
    "nvidia-kernel-module"
  ];
in
lib.filter (name: !(lib.elem name (lib.attrNames ciBuilds.entries))) expected
