#############
# Variables #
#############

# XDG base directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export EDITOR=nvim
export VISUAL=nvim
export GPG_TTY=$(tty)  # Allow GPG signing

# Force packages to use XDG base directories
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
export STARSHIP_CACHE="$XDG_CACHE_HOME"/starship/
export GETIPLAYERUSERPREFS="$XDG_DATA_HOME/get_iplayer"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export ANSIBLE_HOME="$XDG_CONFIG_HOME/ansible"
export ANSIBLE_CONFIG="$XDG_CONFIG_HOME/ansible/ansible.cfg"
export ANSIBLE_GALAXY_CACHE_DIR="$XDG_CACHE_HOME/ansible/galaxy_cache"
export WINEPREFIX="$XDG_DATA_HOME/wineprefixes/default"
export TMUX_PLUGIN_MANAGER_PATH="$XDG_STATE_HOME/tmux/plugins"

export KEYTIMEOUT=1

###########
# Aliases #
###########

alias ls='ls -al --color'
alias exa="exa --icons --grid --long --git --all --group-directories-first"
alias vim="nvim"
alias wget="wget --hsts-file=$XDG_CACHE_HOME/wget-hsts"

##########################
# Git Worktree Functions #
##########################

# Used to clone a git repository such that it is setup to use git worktrees.
# The resulting repository will be a bare clone with all git files placed in
# the .git directory. Worktrees can then be added in the root of the repository.
function git-worktree-clone() {
  local repository_url=$1
  local target_directory=$2

  if [ -z $repository_url ]; then
    echo "Usage: git-worktree-clone <repository_url> [<target_directory>]"
    return 1
  fi

  if [ -z $target_directory ]; then
    target_directory=$(basename $repository_url .git)
  fi

  mkdir $target_directory
  git clone --bare --single-branch $repository_url $target_directory/.git

  cd $target_directory || { echo "Failed to change directory to $target_directory. Please execute 'git checkout \$(git commit_-tree \$(git hash-object -t tree /dev/null) < /dev/null)' manually within cloned repository to prepare it for use with git worktrees."; return 2 }

  git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  git fetch --quiet
  git for-each-ref --format='%(refname:short)' refs/heads | xargs -I{} git branch --set-upstream-to=origin/{} {}
}

# Used to add a worktree corresponding to an existing remote branch. The local
# branch will have the remote checked out and be setup to track the remote.
function git-worktree-add() {
  local commit_ish=$1
  local target_directory=$2

  if [ -z $commit_ish ]; then
    echo "Usage: git-worktree-add <commit_ish> [<target_directory>]"
    return 1
  fi

  if [ -z $target_directory ]; then
    target_directory=./$commit_ish
  fi

  git worktree add $target_directory $commit_ish
  return 0
}

# Used to create a new branch based off of the current worktree's branch
# (by default) in the parent directory.
function git-worktree-branch() {
  local new_branch=""
  local base_branch=""
  local target_directory=""

  print_usage() {
    echo "Usage: git-worktree-branch <new_branch> [<base_branch>] [ -d <target_directory> ]"
  }

  while [[ "$1" != "" ]]; do
    case $1 in
      -d | --directory) shift
                        target_directory=$1 ;;
      *) if [ -z "$new_branch" ]; then
          new_branch=$1
        elif [ -z "$base_branch" ]; then
          base_branch=$1
        else
          print_usage
          return 1
        fi
        ;;
    esac
    shift
  done

  if [ -z $new_branch ]; then
    print_usage
    return 1
  fi

  if [ -z "$target_directory" ]; then
    target_directory="./$new_branch"
  fi

  git worktree add --no-track -b $new_branch $target_directory $base_branch

  return 0
}

# Used to remove a git worktree as well as the branch with the corresponding
# name.
function git-worktree-delete() {
  local worktree_name=$1

  if [ -z $worktree_name ]; then
    echo "Usage: $0 <worktree_name>"
    return 1
  fi

  git worktree remove $worktree_name
  git branch -D $worktree_name
}

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
  '__zoxide_z'
)

for cmd in $fzfPreviewCommands; do
  zstyle ":fzf-tab:complete:$cmd:*" fzf-preview 'exa --icons --grid --oneline --group-directories-first $realpath'
done

###############
# Keybindings #
###############

# Enable Vi mode
bindkey -v

# Insert mode keybinds
bindkey '^[k' history-search-backward
bindkey '^[j' history-search-forward
bindkey '^[l' vi-end-of-line
bindkey '^[h' vi-beginning-of-line
bindkey '^[[H' vi-beginning-of-line
bindkey '^[[F' vi-end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[2~' vi-insert
bindkey '^?' backward-delete-char

# Normal mode keybinds
bindkey -M vicmd '^[l' vi-end-of-line
bindkey -M vicmd '^[h' vi-beginning-of-line
bindkey -M vicmd '^[[H' vi-beginning-of-line
bindkey -M vicmd '^[[F' vi-end-of-line
bindkey -M vicmd '^[[3~' delete-char
bindkey -M vicmd '^[[2~' vi-insert

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

# Enable GitHub CLI completions
source "$ZDOTDIR/gh-completions.zsh"

# Enable prompt
eval "$(starship init zsh)"

# Enable fzf integration
eval "$(fzf --zsh)"

# Enable zoxide
eval "$(zoxide init --cmd cd zsh)"

fastfetch
