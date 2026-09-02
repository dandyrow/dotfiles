#!/bin/sh
# Register the Nix-installed herdr-navigator plugin with herdr.
# Runs as a home-manager activation script on every rebuild.
set -eu

plugin_id="herdr-navigator"
src="@herdrNavigator@"
dest="$HOME/.config/herdr/plugins/config/$plugin_id"
registry="$HOME/.config/herdr/plugins.json"

mkdir -p "$dest"
cp -f "$src/herdr-plugin.toml" "$src/h-nav" "$dest/"
chmod +x "$dest/h-nav"

manifest="$dest/herdr-plugin.toml"
root="$dest"

# Create empty registry if absent so jq can operate on it.
[ -f "$registry" ] || echo '[]' > "$registry"

# Add or update the entry; jq writes to a temp file then replaces.
tmp="${registry}.tmp"
if jq -e --arg id "$plugin_id" 'map(select(.plugin_id == $id)) | length > 0' "$registry" >/dev/null 2>&1; then
  jq --arg id "$plugin_id" --arg mp "$manifest" --arg pr "$root" \
    'map(if .plugin_id == $id then .manifest_path = $mp | .plugin_root = $pr else . end)' \
    "$registry" > "$tmp"
else
  jq --arg id "$plugin_id" --arg mp "$manifest" --arg pr "$root" \
    '. + [{plugin_id:$id, name:"Herdr Navigator", version:"0.1.0",
           min_herdr_version:"0.7.4",
           description:"Seamless ctrl+h/j/k/l across herdr panes and Neovim splits.",
           manifest_path:$mp, plugin_root:$pr, enabled:true,
           platforms:["linux","macos"],
           actions:[
             {id:"left",  title:"Navigate left (nvim/herdr)",  contexts:["global"], command:["sh","h-nav","left"]},
             {id:"down",  title:"Navigate down (nvim/herdr)",  contexts:["global"], command:["sh","h-nav","down"]},
             {id:"up",    title:"Navigate up (nvim/herdr)",    contexts:["global"], command:["sh","h-nav","up"]},
             {id:"right", title:"Navigate right (nvim/herdr)", contexts:["global"], command:["sh","h-nav","right"]}
           ]}]' \
    "$registry" > "$tmp"
fi
mv "$tmp" "$registry"
