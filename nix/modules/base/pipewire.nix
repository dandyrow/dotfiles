{ lib, config, ... }:
{
  options.pipewire.enable = lib.mkEnableOption "PipeWire audio";

  config = lib.mkIf config.pipewire.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    # RTKit gives PipeWire real-time scheduling priority.
    security.rtkit.enable = true;
  };
}
