{
  config,
  lib,
  osConfig,
  ...
}:
{
  config.home.file = lib.mkIf (!config.dandyrow.isStandalone && (osConfig.dandyrow.isWork or false)) {
    # Signed with the personal key outside ~/Projects/work/.
    "Projects/work/.gitconfig".text = ''
      [user]
        name = Daniel Lowry
        email = daniel.lowry@kainos.com

      [commit]
        gpgSign = false

      [tag]
        gpgSign = false
    '';
  };
}
