#!/usr/bin/env bash
# worktree.sh — sourced library for the agent scripts; nothing runs until invoked.
set -euo pipefail

parse_branch() {
  BRANCH=""
  FORCE=0
  for arg in "$@"; do
    case "$arg" in
      --force) FORCE=1 ;;
      --*) echo "Usage: $0 <branch> [--force]" >&2; exit 1 ;;
      *) [[ -z "$BRANCH" ]] && BRANCH="$arg" ;;
    esac
  done
  if [[ -z "$BRANCH" ]]; then
    echo "Usage: $0 <branch> [--force]" >&2
    exit 1
  fi
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
