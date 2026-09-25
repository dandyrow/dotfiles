#!/usr/bin/env bash
# issue-body.sh — snapshot, diff and publish issue bodies; GitHub keeps no revision history, so an overwrite is final.
set -euo pipefail

# Indirection so tests can stub the network call.
GH="${GH:-gh}"

backup_root() {
  printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/issue-backups"
}

backup_path() {
  printf '%s\n' "$(backup_root)/issue-$1-$(date -u +%Y%m%dT%H%M%SZ).md"
}

file_length() {
  wc -c <"$1" | tr -d ' '
}

fetch_body() {
  local issue="$1" dest="$2" tmp
  tmp="$(mktemp)"
  # A redirect creates its target before gh runs, so a failed fetch would leave a 0-byte file for --body-file to publish.
  if ! "$GH" issue view "$issue" --json body --jq .body >"$tmp" 2>/dev/null; then
    rm -f "$tmp"
    echo "Error: could not fetch the body of #$issue" >&2
    return 1
  fi
  if [[ ! -s "$tmp" ]]; then
    rm -f "$tmp"
    echo "Error: the body of #$issue came back empty; refusing to snapshot" >&2
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  mv "$tmp" "$dest"
}

# Local checks only, so a malformed file is rejected before any network call.
validate_body() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Error: no such file: $file" >&2
    return 1
  fi
  if [[ ! -s "$file" ]]; then
    echo "Error: $file is empty; refusing to publish" >&2
    return 1
  fi
  if ! head -n 1 "$file" | grep -q '^# '; then
    echo "Error: $file has no top-level '# ' heading; refusing to publish" >&2
    return 1
  fi
}

# Both lengths come from file_length, so multibyte text cannot skew the ratio.
check_shrink() {
  local file="$1" current_len="$2" allow_shrink="$3" new_len
  new_len="$(file_length "$file")"
  if [[ "$allow_shrink" -eq 0 ]] && (( new_len * 2 < current_len )); then
    echo "Error: this would shrink the body from $current_len to $new_len bytes." >&2
    echo "       Pass --allow-shrink if the deletion is intended." >&2
    return 1
  fi
  printf '%s\n' "$new_len"
}

show_diff() {
  local old="$1" new="$2"
  if [[ ! -f "$old" ]]; then
    echo "(no previous snapshot to diff against)"
    return 0
  fi
  git diff --no-index --word-diff=plain --unified=1 "$old" "$new" || true
}

confirm() {
  local prompt="$1"
  [[ "${ASSUME_YES:-0}" -eq 1 ]] && return 0
  local reply
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" == "y" || "$reply" == "Y" ]]
}

cmd_fetch() {
  local issue="${1:?usage: issue-body.sh fetch <issue>}"
  local dest
  dest="$(backup_path "$issue")"
  fetch_body "$issue" "$dest"
  echo "$dest"
}

cmd_push() {
  local issue="" file="" allow_shrink=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --allow-shrink) allow_shrink=1; shift ;;
      -*) echo "Error: unknown flag: $1" >&2; return 1 ;;
      *)
        if [[ -z "$issue" ]]; then issue="$1"
        elif [[ -z "$file" ]]; then file="$1"
        else echo "Error: too many arguments" >&2; return 1
        fi
        shift
        ;;
    esac
  done
  [[ -n "$issue" && -n "$file" ]] || { echo "Usage: issue-body.sh push <issue> <file> [--allow-shrink]" >&2; return 1; }

  validate_body "$file" || return 1

  # The snapshot doubles as the length baseline, keeping both sides in bytes.
  local snapshot current_len new_len
  snapshot="$(backup_path "$issue")"
  if ! fetch_body "$issue" "$snapshot"; then
    echo "Error: refusing to publish #$issue without a restorable snapshot" >&2
    return 1
  fi
  current_len="$(file_length "$snapshot")"
  new_len="$(check_shrink "$file" "$current_len" "$allow_shrink")" || return 1

  echo "Snapshot: $snapshot"
  echo "Body length: $current_len -> $new_len bytes"
  show_diff "$snapshot" "$file"
  confirm "Publish to #$issue?" || { echo "Aborted."; return 1; }

  "$GH" issue edit "$issue" --body-file "$file" >/dev/null
  echo "Published #$issue ($new_len bytes)"
}

usage() {
  cat <<'USAGE'
Usage:
  issue-body.sh fetch <issue>              snapshot the body, print the backup path
  issue-body.sh push <issue> <file>        validate, diff, confirm, then publish
    --allow-shrink                         permit a >50% length reduction
    ASSUME_YES=1                           skip the confirmation prompt

Backups land in $XDG_STATE_HOME/dotfiles/issue-backups (default
~/.local/state/dotfiles/issue-backups). GitHub stores no body history, so they are
the only way back from a bad publish.
USAGE
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    fetch) shift; cmd_fetch "$@" ;;
    push) shift; cmd_push "$@" ;;
    ""| -h|--help|help) usage ;;
    *) usage; exit 1 ;;
  esac
fi
