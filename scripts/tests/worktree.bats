#!/usr/bin/env bats

setup() {
  source "$(dirname "${BATS_TEST_FILENAME}")/../worktree.sh"
  export ROOT="$(mktemp -d)"
}

@test "parse_branch captures branch and defaults FORCE off" {
  parse_branch "feat/nix"
  [[ "${BRANCH}" == "feat/nix" ]]
  [[ "${FORCE}" -eq 0 ]]
}

@test "parse_branch honors --force after the branch" {
  parse_branch "feat/nix" --force
  [[ "${BRANCH}" == "feat/nix" ]]
  [[ "${FORCE}" -eq 1 ]]
}

@test "parse_branch rejects an empty branch" {
  run parse_branch ""
  [[ "${status}" -eq 1 ]]
}

@test "parse_branch rejects a flag-looking branch" {
  run parse_branch --force
  [[ "${status}" -eq 1 ]]
}

@test "resolve_root errors outside a git repository" {
  cd "$ROOT"
  run resolve_root
  [[ "${status}" -eq 1 ]]
}

@test "resolve_root returns the top level inside a git repository" {
  local base="$ROOT"
  git init --quiet "$base/repo"
  cd "$base/repo"
  resolve_root
  [[ "${ROOT}" == "$base/repo" ]]
}

@test "require_main_worktree rejects a ROOT under .worktrees/" {
  ROOT="$ROOT/checkout/.worktrees/some/branch"
  run require_main_worktree
  [[ "${status}" -eq 1 ]]
}

@test "require_main_worktree accepts a plain checkout ROOT" {
  ROOT="$ROOT/checkout"
  run require_main_worktree
  [[ "${status}" -eq 0 ]]
}

# The real scripts cd into ROOT before locating worktrees, so match that.
find_worktree_fixture() {
  local base="$ROOT"
  git init --quiet "$base/main"
  git -C "$base/main" config user.email t@t
  git -C "$base/main" config user.name t
  git -C "$base/main" config commit.gpgSign false
  git -C "$base/main" commit --allow-empty --quiet -m init
  cd "$base/main"
}

@test "find_worktree_path returns the path for a branch with a worktree" {
  find_worktree_fixture
  git worktree add --quiet "$ROOT/wt" -b feat/wt
  [[ "$(find_worktree_path feat/wt)" == "$ROOT/wt" ]]
}

@test "find_worktree_path returns nothing for an unknown branch" {
  find_worktree_fixture
  [[ -z "$(find_worktree_path nope/missing)" ]]
}

@test "cleanup_empty_parents removes the dead leaf's empty ancestors" {
  mkdir -p "$ROOT/.worktrees/a/b/c"
  rmdir "$ROOT/.worktrees/a/b/c"
  cleanup_empty_parents "$ROOT/.worktrees/a/b/c"
  [[ ! -d "$ROOT/.worktrees/a/b" ]]
  [[ ! -d "$ROOT/.worktrees/a" ]]
  [[ -d "$ROOT/.worktrees" ]]
}

@test "cleanup_empty_parents stops at a non-empty parent" {
  mkdir -p "$ROOT/.worktrees/a/b/c"
  touch "$ROOT/.worktrees/a/b/keep.txt"
  rmdir "$ROOT/.worktrees/a/b/c"
  cleanup_empty_parents "$ROOT/.worktrees/a/b/c"
  [[ -d "$ROOT/.worktrees/a/b" ]]
  [[ -f "$ROOT/.worktrees/a/b/keep.txt" ]]
  [[ -d "$ROOT/.worktrees/a" ]]
}

@test "cleanup_empty_parents leaves dirs outside ROOT/.worktrees alone" {
  mkdir -p "$ROOT/elsewhere/a/b/c"
  cleanup_empty_parents "$ROOT/elsewhere/a/b/c"
  [[ -d "$ROOT/elsewhere/a/b/c" ]]
}

@test "cleanup_empty_parents never removes ROOT/.worktrees itself" {
  mkdir -p "$ROOT/.worktrees/sub"
  rmdir "$ROOT/.worktrees/sub"
  cleanup_empty_parents "$ROOT/.worktrees/sub"
  [[ -d "$ROOT/.worktrees" ]]
}
