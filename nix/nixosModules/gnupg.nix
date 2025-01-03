{ lib, config, ... }:
{
  options = {
    gnupg.enable = lib.mkEnableOption "gnupg";
  };

  config = lib.mkIf config.gnupg.enable {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = lib.mkDefault true;
    };
  };
}
