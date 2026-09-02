{
  config,
  lib,
  pkgs,
  ...
}:
let
  dotfilesDir = "${config.home.homeDirectory}/.dotfiles";
  mkLink = relPath: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${relPath}";
  mkConfigLink = name: { ".config/${name}".source = mkLink "${name}/.config/${name}"; };

  # Directories to stow from dotfiles repo.
  configLinks = [
    "agents"
    "bat"
    "btop"
    "copilot"
    "eza"
    "fastfetch"
    "git"
    "herdr"
    "npm"
    "nvim"
    "opencode"
    "starship"
    "yazi"
    "zsh"
  ];
in
{
  home.file = lib.mkMerge (
    # Symlinked from the ~/.dotfiles clone created by the clone-dotfiles adapters.
    map mkConfigLink configLinks
    ++ [
      # Work identity + no GPG signing, pulled into git via includeIf for ~/Projects/work/.
      {
        "Projects/work/.gitconfig".text = ''
          [user]
            name = Daniel Lowry
            email = daniel.lowry@kainos.com

          [commit]
            gpgSign = false

          [tag]
            gpgSign = false
        '';
      }

      # Per-file, not whole-dir: gpg needs 700 on the dir and keeps runtime files (sockets, keyrings) there.
      {
        ".local/share/gnupg/gpg.conf".source = mkLink "gnupg/.local/share/gnupg/gpg.conf";
        ".local/share/gnupg/gpg-agent.conf".source = mkLink "gnupg/.local/share/gnupg/gpg-agent.conf";
        ".local/share/agents/skills/unslop".source = mkLink "agents/.local/share/agents/skills/unslop";
      }
    ]
  );
}
