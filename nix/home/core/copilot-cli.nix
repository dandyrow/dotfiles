{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dandyrow;
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
in
{
  options.dandyrow = {
    wdxCheckout = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Projects/work/EDM-AI/Workday-Extend-Tools";
      description = "Existing private Workday-Extend-Tools checkout used by the WDX CLI.";
    };
  };

  config = {
    home.packages = [
      pkgs.gh
      pkgs.github-copilot-cli
      pkgs.nodejs
      wdx
    ];

    home.sessionVariables = {
      NODE_EXTRA_CA_CERTS =
        if cfg.isStandalone then
          "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        else
          "/etc/ssl/certs/ca-certificates.crt";
    }
    // lib.optionalAttrs cfg.isStandalone {
      COPILOT_HOME = "${config.home.homeDirectory}/.config/copilot";
      COPILOT_SKILLS_DIRS = "${config.xdg.dataHome}/agents/skills";
    };
  };
}
