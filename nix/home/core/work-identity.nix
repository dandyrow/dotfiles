{
  config,
  lib,
  osConfig,
  ...
}:
{
  config.home.file =
    lib.mkIf (if osConfig == null then false else (osConfig.dandyrow.isWork or false))
      {
        # Pulled into git via includeIf for ~/Projects/work/. Signed with the personal key otherwise.
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
