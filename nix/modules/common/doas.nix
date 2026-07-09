{ config, lib, ... }:
{
  options = {
    doas = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      adminGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "wheel" ];
      };
    };
  };

  config = lib.mkIf config.doas.enable {
    security = {
      sudo.enable = lib.mkDefault false;

      doas = {
        enable = true;
        extraRules = [
          {
            groups = config.doas.adminGroups;
            # keepEnv omitted: root must own its HOME/XDG dirs so nix never writes cache files as root into the invoking user's cache.
            persist = true;
          }
        ];
      };
    };
  };
}
