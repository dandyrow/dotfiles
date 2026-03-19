{
  description = "Dandyrow's dotfiles — Home Manager module";

  # No external inputs required. This flake exports a Home Manager module only.
  # All module arguments (config, lib, pkgs) are provided by the consuming flake
  # (e.g. nix-config) when the module is evaluated.
  outputs = { self }: {
    homeManagerModules.default = { config, lib, pkgs, ... }:
      let
        dotfilesDir = "${config.home.homeDirectory}/.dotfiles";
        mkLink = relPath:
          config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${relPath}";
      in
      {
        # Clone the dotfiles repo if not already present, before Home Manager
        # creates symlinks. This ensures fully automatic provisioning — no
        # manual git clone step required on a fresh machine.
        home.activation.cloneDotfiles = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
          if [ ! -d "${dotfilesDir}" ]; then
            ${pkgs.git}/bin/git clone \
              https://github.com/dandyrow/dotfiles.git \
              "${dotfilesDir}"
          fi
        '';

        home.file = {
          ".config/bat".source       = mkLink "bat/.config/bat";
          ".config/btop".source      = mkLink "btop/.config/btop";
          ".config/eza".source       = mkLink "eza/.config/eza";
          ".config/fastfetch".source = mkLink "fastfetch/.config/fastfetch";
          ".config/git".source       = mkLink "git/.config/git";
          ".config/kitty".source     = mkLink "kitty/.config/kitty";
          ".config/nvim".source      = mkLink "neovim/.config/nvim";
          ".config/starship".source  = mkLink "starship/.config/starship";
          ".config/tmux".source      = mkLink "tmux/.config/tmux";
          ".config/yazi".source      = mkLink "yazi/.config/yazi";
          ".config/zsh".source       = mkLink "zsh/.config/zsh";

          # gnupg: symlink individual config files only, not the whole directory.
          # The directory itself is gitignored (runtime files, keyrings, etc.)
          # and gpg requires strict 700 permissions on the directory itself.
          ".local/share/gnupg/gpg.conf".source       = mkLink "gnupg/.local/share/gnupg/gpg.conf";
          ".local/share/gnupg/gpg-agent.conf".source = mkLink "gnupg/.local/share/gnupg/gpg-agent.conf";
        };
      };
  };
}
