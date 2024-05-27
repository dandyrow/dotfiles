#############
# Variables #
#############

# XDG base directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export EDITOR=nvim
export GPG_TTY=$(tty)  # Allow GPG signing

# Force packages to use XDG base directories
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export STARSHIP_CACHE="$XDG_CACHE_HOME"/starship/
export GETIPLAYERUSERPREFS="$XDG_DATA_HOME/get_iplayer"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export ANSIBLE_HOME="$XDG_CONFIG_HOME/ansible"
export ANSIBLE_CONFIG="$XDG_CONFIG_HOME/ansible/ansible.cfg"
export ANSIBLE_GALAXY_CACHE_DIR="$XDG_CACHE_HOME/ansible/galaxy_cache"
export WINEPREFIX="$XDG_DATA_HOME/wineprefixes/default"
export TMUX_PLUGIN_MANAGER_PATH="$XDG_STATE_HOME/tmux/plugins"

###########
# Aliases #
###########

alias ls='ls -al --color'
alias exa="exa --icons --grid --long --git --all --group-directories-first"
alias vim="nvim"
alias wget="wget --hsts-file=$XDG_CACHE_HOME/wget-hsts"

###########
# Options #
###########

# Enable colours
autoload -U colors && colors

# Create cache folder if it doesn't exist
if [ ! -d "$XDG_CACHE_HOME/zsh" ]; then
  mkdir -p "$XDG_CACHE_HOME/zsh"
fi

# History
HISTFILE="$XDG_CACHE_HOME/zsh/history"
HISTSIZE=5000
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
# Prevents commands starting with a space being saved to history, good to hide sensitive commands
setopt hist_ignore_space
# Prevents duplicate commands showing in history
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styles
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# Add commands here which should show directory contents preview in fzf
fzfPreviewCommands=(
  'cd'
  'ls'
  'exa'
)

for cmd in $fzfPreviewCommands; do
  zstyle ":fzf-tab:complete:$cmd:*" fzf-preview 'exa --icons --grid --oneline --group-directories-first $realpath'
done

###############
# Keybindings #
###############

# Enable Vi mode
bindkey -v
bindkey '^[k' history-search-backward
bindkey '^[j' history-search-forward
bindkey '^[l' vi-end-of-line
bindkey '^[h' vi-beginning-of-line

# Change cursor shape for different vi modes
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ ${KEYMAP} = '' ]] || [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

# Needed to return cursor to insert mode after executing command from normal mode
function zle-line-init {
  zle -K viins
  echo -ne "\e[5 q"
}
zle -N zle-line-init

###########
# Plugins #
###########

source $ZDOTDIR/plugin-manager.zsh

pluginRepos=(
  'Aloxaf/fzf-tab'
  'zsh-users/zsh-autosuggestions'
  'zsh-users/zsh-completions'
  'zsh-users/zsh-syntax-highlighting'
)
plugin-load $pluginRepos

omzPlugins=(
  'command-not-found'
)
plugin-omz $omzPlugins

source "$ZDOTDIR/catppuccin_mocha-zsh-syntax-highlighting.zsh"

# Enable completions
autoload -U compinit && compinit

# Enable propmpt
eval "$(starship init zsh)"

# Enable fzf integration
eval "$(fzf --zsh)"

fastfetch
