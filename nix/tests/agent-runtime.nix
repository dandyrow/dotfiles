{
  lib,
  pkgs,
  homeConfigurations,
}:
let
  work = homeConfigurations."dandyrow@wsl".config;
  migration =
    lib.replaceStrings
      [
        (lib.escapeShellArg "${work.home.homeDirectory}/.dotfiles/copilot/.config/copilot")
        (lib.escapeShellArg "${work.xdg.stateHome}/copilot")
      ]
      [
        ''"$testHome/.dotfiles/copilot/.config/copilot"''
        ''"$testHome/.local/state/copilot"''
      ]
      work.home.activation.migrateCopilotState.data;
in
pkgs.runCommand "test-agent-runtime" { nativeBuildInputs = [ pkgs.nodejs ]; } ''
  node ${../../scripts/tests/mcp-smoke.mjs} ${work.dandyrow.mcpServers.canvas-kit-mcp.command}
  test "$(readlink ${
    work.home.file.".config/copilot".source
  })" = ${lib.escapeShellArg "${work.xdg.stateHome}/copilot"}

  testHome="$TMPDIR/home"
  old="$testHome/.dotfiles/copilot/.config/copilot"
  state="$testHome/.local/state/copilot"
  mkdir -p "$old/session-state" "$state"
  printf 'session' > "$old/session-state/example"
  printf 'old config' > "$old/mcp-config.json"
  printf 'managed config' > "$state/mcp-config.json"
  printf 'original' > "$old/config.json"
  printf 'existing' > "$state/config.json"
  run() { "$@"; }
  warnEcho() { echo "$@" >&2; }
  ${migration}
  test "$(cat "$state/session-state/example")" = session
  test "$(cat "$state/mcp-config.json")" = 'managed config'
  test "$(cat "$state/config.json")" = existing
  test "$(cat "$old/session-state/example")" = session
  test -e "$state/.dotfiles-migrated"
  printf 'preserved' > "$state/session-state/example"
  ${migration}
  test "$(cat "$state/session-state/example")" = preserved
  touch "$out"
''
