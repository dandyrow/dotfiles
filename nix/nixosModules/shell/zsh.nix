{ lib, config, ... }:
{
  options = {
    zsh = {
      enable = lib.mkEnableOption "Enables ZSH";
      defaultShell = lib.mkEnableOption "Sets ZSH as default shell for all users";
    };
  };

  config = lib.mkIf config.zsh.enable {
    programs.zsh = {
      enable = true;
      enableBashCompletion = true;
      enableCompletion = true;
      enableLsColors = true;
      histFile = "$HOME/.cache/zsh/history";
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      setOptions = [
        "appendhistory"
        "sharehistory"
        "hist_ignore_space"
        "hist_ignore_all_dups"
        "hist_save_no_dups"
        "hist_ignore_dups"
        "hist_find_no_dups"
      ];
    };
  };
}
