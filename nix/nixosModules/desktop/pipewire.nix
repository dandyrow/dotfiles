{ lib, config, ... }:
{
  options = {
    pipewire.enable = lib.mkEnableOption "pipewire";
  };

  config = lib.mkIf config.pipewire.enable {
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;

      alsa = {
        enable = lib.mkDefault true;
        support32Bit = lib.mkDefault true;
      };

      pulse.enable = lib.mkDefault true;
    };
  };
}
