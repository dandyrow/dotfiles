#!/usr/bin/env bash
# worktree.sh — sourced library for the agent scripts; nothing runs until invoked.
set -euo pipefail

parse_branch() {
  BRANCH=""
  FORCE=0
  local allow_force=0
  if [[ "${1:-}" == "--allow-force" ]]; then
    allow_force=1
    shift
  fi
  for arg in "$@"; do
    case "$arg" in
      --force)
        if [[ "$allow_force" -eq 1 ]]; then
          FORCE=1
        else
          error_usage "$allow_force"
        fi ;;
      --*) error_usage "$allow_force" ;;
      *) [[ -z "$BRANCH" ]] && BRANCH="$arg" ;;
    esac
  done
  if [[ -z "$BRANCH" ]]; then
    error_usage "$allow_force"
  fi
}

error_usage() {
  local msg="Usage: $0 <branch>"
  [[ "${1:-}" -eq 1 ]] && msg+=" [--force]"
  echo "$msg" >&2
  exit 1
}

resolve_root() {
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "Error: not inside a git repository." >&2
    exit 1
  fi
  ROOT="$(git rev-parse --show-toplevel)"
}

# Refuse to run from inside .worktrees/ — the cwd would be removed from under us.
require_main_worktree() {
  if [[ "$ROOT" == */.worktrees/* ]]; then
    echo "Error: refuse to run from inside a worktree. cd to the main checkout first." >&2
    exit 1
  fi
}

find_worktree_path() {
  local branch="$1"
  git worktree list --porcelain | awk -v branch="refs/heads/$branch" '
    /^worktree / { path = substr($0, 10) }
    /^branch /   { if ($2 == branch) { print path; exit } }
  '
}

cleanup_empty_parents() {
  local path="$1"
  local parent
  if [[ "$path" == "$ROOT/.worktrees/"* ]]; then
    parent="$(dirname "$path")"
    while [[ "$parent" == "$ROOT/.worktrees/"* ]]; do
      rmdir "$parent" 2>/dev/null || break
      parent="$(dirname "$parent")"
    done
  fi
}
