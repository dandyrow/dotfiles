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

    # Video Thumbnailer
    ffmpeg-headless
    ffmpegthumbnailer

    # Raw Thumbnailer
    gdk-pixbuf
    # Allow gdk-pixbuf to thumbnail RAW photos by extracting the embedded jpeg
    (writeTextFile {
      name = "raw-embedded-jpeg-thumbnailer";
      destination = "/share/thumbnailers/raw-embedded-jpeg.thumbnailer";
      text = ''
        [Thumbnailer Entry]
        TryExec=gdk-pixbuf-thumbnailer
        Exec=gdk-pixbuf-thumbnailer -s %s %u %o
        MimeType=image/x-canon-crw;image/x-canon-cr2;image/x-canon-cr3;image/x-adobe-dng;image/x-dng;
      '';
    })
  ];
}
