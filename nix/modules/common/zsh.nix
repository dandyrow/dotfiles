{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    zsh.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf config.zsh.enable {
    # ttf-dejavu-nerd is required by the zsh config for prompt glyphs.
    fonts.packages = [ pkgs.nerd-fonts.dejavu-sans-mono ];

    programs = {
      zsh = {
        enable = true;
        enableCompletion = true;
        enableBashCompletion = true;
        enableLsColors = true;

        histFile = "$HOME/.cache/zsh/history";
        histSize = 5000;

        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;

        # hist_ignore_space: remove command lines from history when first character is a space
        # dups options: prevent duplicates from being stored in the history
        setOptions = [
          "appendhistory"
          "sharehistory"
          "hist_ignore_space"
          "hist_ignore_all_dups"
          "hist_save_no_dups"
          "hist_ignore_dups"
          "hist_find_no_dups"
        ];

        # Set ZDOTDIR system-wide so zsh finds the user config before any shell
        # initialisation runs. home.sessionVariables is too late — zsh reads
        # /etc/zsh/zshenv before it knows where ZDOTDIR is.
        shellInit = ''
          export ZDOTDIR="$HOME/.config/zsh"
        '';
      };

      nix-index = {
        enable = true;
        enableZshIntegration = true;
      };
    };
  };
}
