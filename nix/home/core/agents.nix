{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dandyrow;
  copilotHome = "${config.xdg.stateHome}/copilot";
  wdx = pkgs.writeShellApplication {
    name = "wdx";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      cli=${lib.escapeShellArg "${cfg.wdxCheckout}/vscode-extension/cli/bin/wdx.js"}
      if [ ! -f "$cli" ]; then
        echo "WDX checkout missing: $cli. Restore Workday-Extend-Tools as described in docs/wsl-development.md." >&2
        exit 1
      fi
      exec node "$cli" "$@"
    '';
  };
  declared = (lib.importJSON ../../../copilot/.config/copilot/mcp-config.json).mcpServers;
  servers = lib.filterAttrs (name: _: name != "wdx" || cfg.isWork) (
    declared
    // {
      canvas-kit-mcp = declared.canvas-kit-mcp // {
        command = lib.getExe pkgs.canvas-kit-mcp;
      };
      wdx = declared.wdx // {
        command = lib.getExe wdx;
      };
    }
  );
  files = {
    "mcp-config.json".text = builtins.toJSON { mcpServers = servers; };
    "settings.json".text =
      lib.replaceStrings
        [ "/home/dandyrow/.config/copilot" "/home/dandyrow" ]
        [ copilotHome config.home.homeDirectory ]
        (builtins.readFile ../../../copilot/.config/copilot/settings.json);
    "copilot-instructions.md".source = ../../../copilot/.config/copilot/copilot-instructions.md;
    "hooks".source = ../../../copilot/.config/copilot/hooks;
  };
in
{
  options.dandyrow = {
    wdxCheckout = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Projects/work/EDM-AI/Workday-Extend-Tools";
      description = "Existing private Workday-Extend-Tools checkout used by the WDX CLI.";
    };
    mcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      readOnly = true;
      default = servers;
      description = "Shared MCP server definitions for Copilot CLI and VS Code.";
    };
  };

  config = {
    home.packages = [
      pkgs.gh
      pkgs.github-copilot-cli
      pkgs.canvas-kit-mcp
    ]
    ++ lib.optional cfg.isWork wdx;

    home.sessionVariables = {
      COPILOT_HOME = copilotHome;
      COPILOT_SKILLS_DIRS = "${config.xdg.dataHome}/agents/skills";
      NODE_EXTRA_CA_CERTS =
        if cfg.isStandalone then
          "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        else
          "/etc/ssl/certs/ca-certificates.crt";
    };

    xdg.configFile = lib.mapAttrs' (
      name: value: lib.nameValuePair "copilot-managed/${name}" value
    ) files;

    home.file =
      lib.mapAttrs' (
        name: _:
        lib.nameValuePair "${copilotHome}/${name}" {
          source = config.xdg.configFile."copilot-managed/${name}".source;
        }
      ) files
      // {
        # Existing plugin records contain absolute paths beneath the old COPILOT_HOME.
        ".config/copilot".source = config.lib.file.mkOutOfStoreSymlink copilotHome;
      };

    home.activation.migrateCopilotState = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      old=${lib.escapeShellArg "${config.home.homeDirectory}/.dotfiles/copilot/.config/copilot"}
      state=${lib.escapeShellArg copilotHome}
      if [ -d "$old" ] && [ ! -e "$state/.dotfiles-migrated" ]; then
        for entry in "$old"/* "$old"/.[!.]* "$old"/..?*; do
          [ -e "$entry" ] || continue
          name="$(basename "$entry")"
          case "$name" in
            mcp-config.json|settings.json|copilot-instructions.md|hooks) continue ;;
          esac
          if [ -e "$state/$name" ]; then
            warnEcho "Keeping existing Copilot state: $state/$name; original remains at $entry"
          else
            run cp -a "$entry" "$state/$name"
          fi
        done
        run touch "$state/.dotfiles-migrated"
      fi
    '';
  };
}
