{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = config.dandyrow;
  sbxCfg = config.dandyrow.sbxIdentity or { };
  enabled = (sbxCfg.enable or false) && osConfig != null && !cfg.isStandalone;

  kitList = if osConfig == null then [ ] else lib.attrNames (osConfig.sbx.kits or { });

  agentSbx = pkgs.writeShellApplication {
    name = "agent-sbx";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.jq
    ];
    text = ''
      die() {
        printf '%s\n' "$*" >&2
        exit 1
      }

      usage() {
        printf 'usage: agent-sbx <opencode|copilot> [-- agent args]\n' >&2
        exit 2
      }

      agent="''${1:-}"
      case "$agent" in
        opencode|copilot)
          shift
          ;;
        *)
          usage
          ;;
      esac

      if [ "''${1:-}" = "--" ]; then
        shift
      fi

      git_ident_name=${lib.escapeShellArg (sbxCfg.gitIdentity.name or "")}
      git_ident_email=${lib.escapeShellArg (sbxCfg.gitIdentity.email or "")}
      if [ -z "$git_ident_name" ] || [ -z "$git_ident_email" ]; then
        die "agent-sbx: missing git identity"
      fi

      is_wsl=${if (sbxCfg.isWsl or false) then "1" else "0"}
      mint_cmd=${lib.escapeShellArg (sbxCfg.github.mintCommand or "sbx-github-mint")}

      common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || die "agent-sbx: not inside a git repository"
      root="$(dirname "$common_dir")"

      repo_basename="$(basename "$root")"
      name="$agent-$repo_basename"

      origin_url="$(git -C "$root" config --get remote.origin.url 2>/dev/null || true)"
      origin_url_lower="''${origin_url,,}"
      if [[ "$origin_url_lower" =~ github\.com[:/]([^/]+)/ ]]; then
        if [[ "''${BASH_REMATCH[1],,}" == "dandyrow" ]]; then
          personal=1
        else
          personal=0
        fi
      elif [[ -n "$origin_url" ]]; then
        personal=0
      elif [[ -n "''${HOME:-}" && "$root/" == "$HOME/Projects/work/"* ]]; then
        personal=0
      else
        personal=1
      fi

      exists=0
      ls_json="$(sbx ls --json 2>&1)" || die "agent-sbx: failed to run 'sbx ls --json': $ls_json"
      printf '%s' "$ls_json" | jq -e '((.sandboxes // []) | type) == "array"' >/dev/null 2>&1 \
        || die "agent-sbx: unexpected 'sbx ls --json' output"
      if printf '%s' "$ls_json" | jq -e --arg n "$name" '.sandboxes[]? | select(.name == $n)' >/dev/null; then
        exists=1
      fi

      flags=(--name "$name")
      flags+=(-e "GIT_AUTHOR_NAME=$git_ident_name")
      flags+=(-e "GIT_AUTHOR_EMAIL=$git_ident_email")
      flags+=(-e "GIT_COMMITTER_NAME=$git_ident_name")
      flags+=(-e "GIT_COMMITTER_EMAIL=$git_ident_email")

      kit_list=${lib.escapeShellArg (builtins.toJSON kitList)}

      add_kit() {
        local kit="$1" required="$2"
        if printf '%s' "$kit_list" | jq -e --arg kit "$kit" 'index($kit)' >/dev/null; then
          flags+=(--kit "/etc/sbx-kits/$kit.zip")
        elif [ "$required" -eq 1 ]; then
          die "agent-sbx: $kit kit required for $agent on this host"
        fi
      }

      if [ "$exists" -eq 0 ]; then
        flags+=(--clone)
        add_kit agent-gate 1
        if [ "$is_wsl" -eq 1 ]; then
          add_kit corp-ca 0
          if [ "$agent" = "opencode" ]; then
            add_kit opencode-copilot 1
          fi
        fi
        if [ "$agent" = "copilot" ]; then
          add_kit copilot-mcp 1
        fi

        mcp_list_json="$(sbx mcp ls --json 2>&1)" || die "agent-sbx: failed to run 'sbx mcp ls --json': $mcp_list_json"
        static_mcp="$(printf '%s' "$mcp_list_json" | jq -r '[.servers[]?.name] | join(",")' 2>&1)" || die "agent-sbx: failed to parse mcp list"
        if [ -n "$static_mcp" ]; then
          flags+=(--static-mcp "$static_mcp")
        fi

        if [ "$is_wsl" -eq 1 ] && [ "$personal" -eq 1 ]; then
          sbx secret set github --sandbox "$name" --command "$mint_cmd"
        fi
      fi

      printf 'agent-sbx: repo=%s sandbox=%s %s\n' "$repo_basename" "$name" "$(if [ "$exists" -eq 1 ]; then echo reattach; else echo create; fi)" >&2
      cd "$root"
      exec sbx run "$agent" "''${flags[@]}" -- "$@"
    '';
  };
in
{
  imports = [
    ../facts.nix
    ./sbx-identity.nix
  ];

  config = lib.mkIf enabled {
    home.packages = [ agentSbx ];
  };
}
