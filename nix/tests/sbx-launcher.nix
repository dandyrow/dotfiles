{ lib, pkgs }:
let
  fakeSbx = pkgs.writeShellScriptBin "sbx" ''
    log="''${FAKE_SBX_LOG:?}"
    {
      printf 'cwd=%s\n' "$PWD"
      printf 'call='
      printf '%s ' "$@"
      printf '\n'
    } >>"$log"
    case "''${1:-}" in
      ls)
        [ "''${2:-}" = "--json" ] || exit 1
        cat "''${FAKE_SBX_LS:?}"
        ;;
      mcp)
        [ "''${2:-}" = "ls" ] && [ "''${3:-}" = "--json" ] || exit 1
        cat "''${FAKE_SBX_MCP:?}"
        ;;
      secret)
        exit 0
        ;;
      run)
        exit 0
        ;;
      *)
        exit 1
        ;;
    esac
  '';

  osConfig =
    { isWsl, kits }:
    {
      sbx = {
        enable = true;
        kits = lib.genAttrs kits (_: { });
      };
      wsl.enable = isWsl;
      networking.hostName = if isWsl then "WSL" else "DansSpectre";
    };

  launcherPackage =
    os:
    let
      packages =
        (lib.evalModules {
          specialArgs = {
            osConfig = os;
            inherit pkgs;
          };
          modules = [
            ../home/core/sbx-launcher.nix
            {
              options.home.packages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [ ];
              };
            }
          ];
        }).config.home.packages;
    in
    builtins.head (builtins.filter (p: (p.name or "") == "agent-sbx") packages);

  runCase =
    {
      name,
      isWsl ? false,
      kits ? [ "agent-gate" ],
      repoSetup,
      agent,
      agentArgs ? "",
      ls ? ''{"sandboxes":[]}'',
      mcp ? ''{"servers":[]}'',
      checks ? [ ],
      notContains ? [ ],
      cwdVar ? null,
      noSecret ? false,
      noRun ? false,
      exitCode ? null,
    }:
    let
      lsJson = builtins.toFile "${name}-ls.json" ls;
      mcpJson = builtins.toFile "${name}-mcp.json" mcp;
      checkLines = lib.concatStringsSep "\n" (
        map (check: ''
          grep -F -- ${lib.escapeShellArg check} "$FAKE_SBX_LOG" >/dev/null || {
            echo "FAIL: missing ${check}" >&2
            cat "$FAKE_SBX_LOG" >&2
            exit 1
          }
        '') checks
      );
      forbidden = notContains ++ lib.optional noSecret "call=secret set" ++ lib.optional noRun "call=run";
      forbiddenLines = lib.concatStringsSep "\n" (
        map (check: ''
          if grep -F -- ${lib.escapeShellArg check} "$FAKE_SBX_LOG" >/dev/null; then
            echo "FAIL: unexpected ${check}" >&2
            cat "$FAKE_SBX_LOG" >&2
            exit 1
          fi
        '') forbidden
      );
      cwdLine = lib.optionalString (cwdVar != null) ''
        grep -Fx -- "cwd=''${${cwdVar}}" "$FAKE_SBX_LOG" >/dev/null || {
          echo "FAIL: run did not happen from ''${${cwdVar}}" >&2
          cat "$FAKE_SBX_LOG" >&2
          exit 1
        }
      '';
      exitLine = lib.optionalString (exitCode != null) ''
        [ "$rc" = "${toString exitCode}" ] || {
          echo "FAIL: expected exit ${toString exitCode}, got $rc" >&2
          cat "$TMPDIR/stderr" >&2
          exit 1
        }
      '';
    in
    pkgs.runCommand "test-sbx-launcher-${name}"
      {
        nativeBuildInputs = [
          fakeSbx
          pkgs.coreutils
          pkgs.git
          pkgs.jq
        ];
      }
      ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        export GIT_CONFIG_GLOBAL="$TMPDIR/gitconfig"
        export GIT_CONFIG_NOSYSTEM=1
        git config --global user.name test
        git config --global user.email test@example.com
        git config --global commit.gpgsign false

        export FAKE_SBX_LOG="$TMPDIR/sbx.log"
        export FAKE_SBX_LS=${lsJson}
        export FAKE_SBX_MCP=${mcpJson}
        export PATH=${fakeSbx}/bin:$PATH

        ${repoSetup}

        set +e
        ${
          launcherPackage (osConfig {
            inherit isWsl kits;
          })
        }/bin/agent-sbx ${agent} ${agentArgs} >"$TMPDIR/stdout" 2>"$TMPDIR/stderr"
        rc=$?
        set -e

        touch "$FAKE_SBX_LOG"
        ${checkLines}
        ${forbiddenLines}
        ${cwdLine}
        ${exitLine}
        touch $out
      '';

  mkRepos = ''
    git init -q "$TMPDIR/dotfiles"
    git -C "$TMPDIR/dotfiles" remote add origin https://github.com/dandyrow/dotfiles.git
    cd "$TMPDIR/dotfiles"
  '';

  mkKainos = ''
    git init -q "$TMPDIR/dotfiles"
    git -C "$TMPDIR/dotfiles" remote add origin https://github.com/KainosSoftwareLtd/dotfiles.git
    cd "$TMPDIR/dotfiles"
  '';

  cases = {
    nonwsl-opencode = runCase {
      name = "nonwsl-opencode";
      kits = [
        "agent-gate"
        "copilot-mcp"
      ];
      repoSetup = mkRepos;
      agent = "opencode";
      mcp = ''{"servers":[{"name":"context7"},{"name":"atlassian"}]}'';
      checks = [
        "call=run opencode"
        "call=mcp ls --json"
        "--name opencode-dotfiles"
        "--clone"
        "--kit /etc/sbx-kits/agent-gate.zip"
        "--static-mcp context7,atlassian"
        "GIT_AUTHOR_NAME=opencode-agent[bot]"
        "GIT_AUTHOR_EMAIL=219766164+opencode-agent[bot]@users.noreply.github.com"
      ];
      notContains = [
        "corp-ca"
        "opencode-copilot"
        "copilot-mcp"
      ];
      noSecret = true;
    };

    wsl-opencode-personal = runCase {
      name = "wsl-opencode-personal";
      isWsl = true;
      kits = [
        "agent-gate"
        "corp-ca"
        "opencode-copilot"
      ];
      repoSetup = mkRepos;
      agent = "opencode";
      checks = [
        "--clone"
        "--kit /etc/sbx-kits/agent-gate.zip"
        "--kit /etc/sbx-kits/corp-ca.zip"
        "--kit /etc/sbx-kits/opencode-copilot.zip"
        "GIT_AUTHOR_NAME=Copilot"
        "GIT_AUTHOR_EMAIL=198982749+Copilot@users.noreply.github.com"
        "call=secret set github --sandbox opencode-dotfiles --command sbx-github-mint"
      ];
      notContains = [ "copilot-mcp" ];
    };

    wsl-copilot-kainos = runCase {
      name = "wsl-copilot-kainos";
      isWsl = true;
      kits = [
        "agent-gate"
        "corp-ca"
        "copilot-mcp"
      ];
      repoSetup = mkKainos;
      agent = "copilot";
      checks = [
        "--clone"
        "--kit /etc/sbx-kits/agent-gate.zip"
        "--kit /etc/sbx-kits/corp-ca.zip"
        "--kit /etc/sbx-kits/copilot-mcp.zip"
        "GIT_AUTHOR_NAME=Copilot"
      ];
      notContains = [ "opencode-copilot" ];
      noSecret = true;
    };

    wsl-opencode-no-origin-work = runCase {
      name = "wsl-opencode-no-origin-work";
      isWsl = true;
      kits = [
        "agent-gate"
        "corp-ca"
        "opencode-copilot"
      ];
      repoSetup = ''
        mkdir -p "$HOME/Projects/work"
        git init -q "$HOME/Projects/work/repo"
        cd "$HOME/Projects/work/repo"
      '';
      agent = "opencode";
      checks = [ "--clone" ];
      noSecret = true;
    };

    wsl-opencode-no-origin-personal = runCase {
      name = "wsl-opencode-no-origin-personal";
      isWsl = true;
      kits = [
        "agent-gate"
        "corp-ca"
        "opencode-copilot"
      ];
      repoSetup = ''
        mkdir -p "$HOME/Projects/personal"
        git init -q "$HOME/Projects/personal/repo"
        cd "$HOME/Projects/personal/repo"
      '';
      agent = "opencode";
      checks = [ "call=secret set github --sandbox opencode-repo --command sbx-github-mint" ];
    };

    reattach = runCase {
      name = "reattach";
      repoSetup = mkRepos;
      agent = "opencode";
      ls = ''{"sandboxes":[{"name":"opencode-dotfiles"}]}'';
      mcp = ''{"servers":[{"name":"context7"}]}'';
      checks = [
        "call=run opencode"
        "GIT_AUTHOR_NAME=opencode-agent[bot]"
        "GIT_AUTHOR_EMAIL=219766164+opencode-agent[bot]@users.noreply.github.com"
      ];
      notContains = [
        "--clone"
        "--kit"
        "--static-mcp"
        "secret set"
      ];
    };

    worktree = runCase {
      name = "worktree";
      repoSetup = ''
        MAIN="$TMPDIR/main"
        git init -q "$MAIN"
        git -C "$MAIN" remote add origin https://github.com/dandyrow/dotfiles.git
        printf 'x\n' >"$MAIN/x"
        git -C "$MAIN" add x
        git -C "$MAIN" commit -qm init
        git -C "$MAIN" worktree add -q "$TMPDIR/wt" -b feat/test
        cd "$TMPDIR/wt"
      '';
      agent = "opencode";
      checks = [ "--clone" ];
      cwdVar = "MAIN";
    };

    invalid-agent = runCase {
      name = "invalid-agent";
      repoSetup = mkRepos;
      agent = "badagent";
      noRun = true;
      exitCode = 2;
    };
  };
in
pkgs.runCommand "test-sbx-launcher" {
  buildInputs = builtins.attrValues cases;
} "touch $out"
