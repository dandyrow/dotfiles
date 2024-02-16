# Set XDG base directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

###############
# ZSH Options #
###############

# Enable colours
autoload -U colors && colors

# Create cache folder if it doesn't exist
if [ ! -d "$XDG_CACHE_HOME/zsh" ]; then
  mkdir -p "$XDG_CACHE_HOME/zsh"
fi

# Set history options
HISTFILE="$XDG_CACHE_HOME/zsh/history"
HISTSIZE=1000
SAVEHIST=1000

# Tab completion
autoload -U compinit
zstyle ':completion:*' menu select
# Auto complete with case insesitivity
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
zmodload zsh/complist
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
_comp_options+=(globdots)

# vi mode
bindkey -v
export KEYTIMEOUT=1

############
# Keybinds #
############

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -A key

key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}
key[Shift-Tab]=${terminfo[kcbt]}
key[Control-Left]=${terminfo[kLFT5]}
key[Control-Right]=${terminfo[kRIT5]}

for k in ${(k)key} ; do
    # $terminfo[] entries are weird in ncurses application mode...
    [[ ${key[$k]} == $'\eO'* ]] && key[$k]=${key[$k]/O/[}
done
unset k

# Bind special keys in vi insert mode then vi cmd mode if key is non-empty
[[ -n "${key[Home]}"          ]] && bindkey "${key[Home]}"          vi-beginning-of-line    && bindkey -a "${key[Home]}"          vi-beginning-of-line
[[ -n "${key[End]}"           ]] && bindkey "${key[End]}"           vi-end-of-line          && bindkey -a "${key[End]}"           vi-end-of-line
[[ -n "${key[Insert]}"        ]] && bindkey "${key[Insert]}"        vi-replace              && bindkey -a "${key[Insert]}"        vi-replace
[[ -n "${key[Delete]}"        ]] && bindkey "${key[Delete]}"        vi-delete-char          && bindkey -a "${key[Delete]}"        vi-delete-char
[[ -n "${key[Up]}"            ]] && bindkey "${key[Up]}"            vi-up-line-or-history   && bindkey -a "${key[Up]}"            vi-up-line-or-history
[[ -n "${key[Down]}"          ]] && bindkey "${key[Down]}"          vi-down-line-or-history && bindkey -a "${key[Down]}"          vi-down-line-or-history
[[ -n "${key[Left]}"          ]] && bindkey "${key[Left]}"          vi-backward-char        && bindkey -a "${key[Left]}"          vi-backward-char
[[ -n "${key[Right]}"         ]] && bindkey "${key[Right]}"         vi-forward-char         && bindkey -a "${key[Right]}"         vi-forward-char
[[ -n "${key[PageDown]}"      ]] && bindkey "${key[PageDown]}"      vi-forward-blank-word   && bindkey -a "${key[PageDown]}"      vi-forward-blank-word
[[ -n "${key[PageUp]}"        ]] && bindkey "${key[PageUp]}"        vi-backward-blank-word  && bindkey -a "${key[PageUp]}"        vi-backward-blank-word
[[ -n "${key[Shift-Tab]}"     ]] && bindkey "${key[Shift-Tab]}"     reverse-menu-complete   && bindkey -a "${key[Shift-Tab]}"     reverse-menu-complete
[[ -n "${key[Control-Left]}"  ]] && bindkey "${key[Control-Left]}"  vi-backward-word        && bindkey -a "${key[Control-Left]}"  vi-backward-word
[[ -n "${key[Control-Right]}" ]] && bindkey "${key[Control-Right]}" vi-forward-word         && bindkey -a "${key[Control-Right]}" vi-forward-word

# finally, make sure the terminal is in application mode, when zle is
# active. only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

# Use vim keys in tab complete menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'left' vi-backward-char
bindkey -M menuselect 'down' vi-down-line-or-history
bindkey -M menuselect 'up' vi-up-line-or-history
bindkey -M menuselect 'right' vi-forward-char
# Fix backspace bug when switching modes
bindkey "^?" backward-delete-char

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
zle-line-init() {
  zle -K viins
  echo -ne "\e[5 q"
}
zle -N zle-line-init

echo -ne '\e[5 q'

# Edit line in vim with ctrl-v
autoload edit-command-line; zle -N edit-command-line
bindkey '^v' edit-command-line

# Control bindings for programs
bindkey -s "^w" "clear\n"
bindkey -s "^r" "source $ZDOTDIR/.zshrc\n" 

######################
# Source ZSH plugins #
######################

if [ -f /etc/os-release ]; then
  . /etc/os-release
  
  if [[ $ID == debian ]]; then
    # Load zsh-autosuggestions
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    
    # Load zsh-syntax-highlighting
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

    # Load command not found handler for zsh on debian based distros
    source /etc/zsh_command_not_found
  elif [[ $ID == arch ]]; then
    # Load zsh-autosuggestions
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    
    # Load zsh-syntax-highlighting
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

    # Load command not found hook from pkgfile
    source /usr/share/doc/pkgfile/command-not-found.zsh
  fi
fi

# Load catppuccin theme for syntac highlighting
source "$XDG_CONFIG_HOME/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh"

#################
# Variables #
#################

export EDITOR=nvim
export PATH="$HOME/.local/bin:$PATH"  # Add install location of pip binaries to path
export GPG_TTY=$(tty)  # Allow GPG signing

# Variables to force software to use XDG base directories
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

alias ls="ls -al"
alias exa="exa --icons --grid --long --git --all"
alias vim="nvim"
alias wget="wget --hsts-file=$XDG_CACHE_HOME/wget-hsts"

# Make following commands safer with interactive mode (learnt the hard way)
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

############
# Neofetch #
# ##########

neofetch

##########
# Prompt #
##########

eval "$(starship init zsh)"

