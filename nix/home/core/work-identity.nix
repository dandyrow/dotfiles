{
  config,
  lib,
  ...
}:
{
  options.dandyrow.isWork = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether this machine is Daniel's work machine.";
  };

  config.home.file = lib.mkIf config.dandyrow.isWork {
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
