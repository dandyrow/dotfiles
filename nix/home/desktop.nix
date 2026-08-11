{
  lib,
  osConfig,
  ...
}:
{
  options.dandyrow.hasDesktop = lib.mkOption {
    type = lib.types.bool;
    # Named for the concept, not the signal — a second DE joins this disjunction without touching consumers.
    default = osConfig != null && (osConfig.gnome.enable or false);
    defaultText = lib.literalExpression "osConfig != null && (osConfig.gnome.enable or false)";
    description = ''
      Whether this machine runs a graphical desktop environment.

      Derived from the host NixOS configuration when Home Manager runs as a
      NixOS module. Standalone Home Manager derives `false` and may override
      this to `true`.
    '';
  };
}
