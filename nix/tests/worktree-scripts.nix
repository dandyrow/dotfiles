{
  pkgs,
}:
let
  # Copy the scripts dir so tests can source worktree.sh and run against worktree.bats.
  scripts = builtins.path {
    path = ../../scripts;
    name = "agent-scripts";
  };
in
pkgs.runCommand "test-worktree-scripts"
  {
    nativeBuildInputs = [
      pkgs.bats
      pkgs.git
      pkgs.coreutils
      pkgs.gawk
    ];
  }
  ''
    ${pkgs.bats}/bin/bats --formatter tap ${scripts}/tests
    touch $out
  ''
