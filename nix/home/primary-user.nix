{
  config,
  lib,
  osConfig,
  ...
}:
{
  options.dandyrow.primaryUser = lib.mkOption {
    type = lib.types.str;
    default = "dandyrow";
    description = ''
      Login name of the human this configuration belongs to. Read only off
      NixOS; as a NixOS module, Home Manager takes the name from the NixOS user
      instead, so setting this there has no effect.
    '';
  };

  config = lib.mkIf (osConfig == null) {
    home = {
      username = config.dandyrow.primaryUser;
      homeDirectory = "/home/${config.dandyrow.primaryUser}";
    };
  };
}
