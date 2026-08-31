{
  config,
  lib,
  osConfig,
  ...
}:
{
  options.dandyrow = {
    # Home Manager supplies osConfig, null when it runs standalone off NixOS.
    isStandalone = lib.mkOption {
      type = lib.types.bool;
      default = osConfig == null;
      defaultText = lib.literalExpression "osConfig == null";
      description = ''
        Whether Home Manager runs standalone (outside the NixOS module system)
        and must provide for itself what NixOS would otherwise supply.
      '';
    };

    hasDesktop = lib.mkOption {
      type = lib.types.bool;
      default = if config.dandyrow.isStandalone then false else (osConfig.gnome.enable or false);
      defaultText = lib.literalExpression ''
        if config.dandyrow.isStandalone then false else (osConfig.gnome.enable or false)
      '';
      description = ''
        Whether this machine runs a graphical desktop environment.

        Standalone Home Manager derives `false` and may override this to `true`.
        As a NixOS module it follows the host's GNOME state.
      '';
    };

    primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "dandyrow";
      description = ''
        Login name of the human this configuration belongs to. Read only off
        NixOS; as a NixOS module, Home Manager takes the name from the NixOS user
        instead, so setting this there has no effect.
      '';
    };
  };
}
