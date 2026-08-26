{
  config,
  lib,
  pkgs,
  # No default — HM always supplies it, null off NixOS.
  osConfig,
  ...
}:
{
  # GNUPGHOME must be in the systemd user environment so gpg-agent (launched
  # as a systemd user service at login) uses the XDG path rather than ~/.gnupg.
  systemd.user = {
    sessionVariables = {
      GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    };
    # gpg requires strict 700 permissions on its home directory.
    tmpfiles.rules = [
      "d %h/.local/share/gnupg 0700 - - -"
    ];
  };

  # gnupg is provided system-wide on NixOS via the gnupg common module;
  # only add it here for standalone Home Manager (non-NixOS).
  home.packages = lib.optionals (osConfig == null) [ pkgs.gnupg ];
}
