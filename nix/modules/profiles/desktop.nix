# Desktop profile — import in hosts that run a graphical desktop.
# Loads all desktop modules and enables them by default.
# Override per-host with e.g. `gnome.enable = lib.mkForce false`.
{ pkgs, ... }:
{
  imports = [
    ../desktop
  ];

  gnome.enable = true;
  pipewire.enable = true;
  printing.enable = true;

  environment.systemPackages = with pkgs; [
    vlc
    darktable
    libreoffice-fresh
  ];
}
