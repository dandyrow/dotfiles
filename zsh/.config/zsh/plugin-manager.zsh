ZPLUGINDIR=${ZPLUGINDIR:-${ZDOTDIR:-${$XDG_CONFIG_HOME:-$HOME/.config}/zsh}/plugins}

# Takes in an array of GitHub repos each containing a single ZSH plugin,
# clones the repos then sources each of the plugins in order.
#
# For non-sourcable plugins use only plugin-clone below.
# For repos with nested plugins use plugin-clone to clone then use
# plugin-source to source each nested plugin.
function plugin-load {
  plugin-clone $@

  pluginDirs=()
  for repo in $@; do
    pluginDirs+=${repo:t}
  done

  plugin-source $pluginDirs
}

# Takes in an array of names of ohmyzsh plugins which are found in the plugins
# directory of the ohmyzsh repository, clones the ohmyzsh repo and installs
# the plugins passed in.
function plugin-omz {
  repos=('ohmyzsh/ohmyzsh')
  plugin-clone $repos

  pluginDirs=()
  for plugin in $@; do
    pluginDirs+="ohmyzsh/plugins/$plugin"
  done

  plugin-source $pluginDirs
}

# Takes in an array of GitHub repos and clones them into the plugin directory.
# The plugin directory is made up of the $ZPLUGINDIR and the name of the plugin.
function plugin-clone {
  local repo pluginDir initFile initFiles=()

  for repo in $@; do
    pluginDir=$ZPLUGINDIR/${repo:t}
    initFile=$pluginDir/${repo:t}.plugin.zsh

    if [[ ! -d $pluginDir ]]; then
      echo "Cloning $repo..."
      git clone -q --depth 1 --recursive --shallow-submodules \
        https://github.com/$repo $pluginDir
    fi

    # If initFile doesn't exist, search for all files matching pattern in
    # pluginDir and link initFile to first item in initFiles array.
    if [[ ! -e $initFile ]]; then
      initFiles=($pluginDir/*.{plugin.zsh,zsh-theme,zsh,sh}(N))
      (( $#initFiles )) && ln -sf $initFiles[1] $initFile
    fi
  done
}

# Takes in an array of plugin directories and sources the plugin within those
# directories. If using relative paths the plugin directory is prepended with
# the ZPLUGINDIR.
function plugin-source {
  local pluginDir

  for pluginDir in $@; do
    # if pluginDir doesn't start with a / prepend $ZPLUGINDIR
    [[ $pluginDir = /* ]] || pluginDir=$ZPLUGINDIR/$pluginDir
    fpath+=$pluginDir
    source $pluginDir/${pluginDir:t}.plugin.zsh
  done
}

# Updates all plugins in the ZPLUGINDIR by running a git pull to update the
# repos.
function plugin-update {
  local d

  for d in $ZPLUGINDIR/*/.git(/); do
    echo "Updating ${d:h:t}..."
    command git -C "${d:h}" pull --ff --recurse-submodules --depth 1 --rebase --autostash
  done
}
