#!/usr/bin/env bats

setup() {
  source "$(dirname "${BATS_TEST_FILENAME}")/../issue-body.sh"
  export ROOT="$(mktemp -d)"
  export XDG_STATE_HOME="$ROOT/state"
  export ASSUME_YES=1
  printf '# Map\n\nsome body text here\n' >"$ROOT/good.md"
  : >"$ROOT/empty.md"
  printf 'no heading at all\n' >"$ROOT/headingless.md"
  printf '# Map\n\n%s\n' "$(head -c 400 /dev/zero | tr '\0' 'x')" >"$ROOT/long.md"
}

# A stub gh on PATH; view and the snapshot fetch are the same command, so it dispatches on nothing but the subcommand.
stub_gh() {
  local body="$1"
  cat >"$ROOT/gh" <<STUB
#!/usr/bin/env bash
if [[ "\$2" == "view" ]]; then printf '%s' "\$STUB_BODY"
elif [[ "\$2" == "edit" ]]; then printf 'edited %s\n' "\$3" >>"\$GH_LOG"
fi
STUB
  chmod +x "$ROOT/gh"
  export PATH="$ROOT:$PATH"
  export STUB_BODY="$body"
  export GH_LOG="$ROOT/calls.log"
  : >"$GH_LOG"
}

@test "validate_body accepts a well-formed body" {
  run validate_body "$ROOT/good.md"
  [[ "$status" -eq 0 ]]
}

@test "validate_body rejects an empty file" {
  run validate_body "$ROOT/empty.md"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"is empty"* ]]
}

@test "validate_body rejects a missing file" {
  run validate_body "$ROOT/nope.md"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"no such file"* ]]
}

@test "validate_body rejects a body with no top-level heading" {
  run validate_body "$ROOT/headingless.md"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"no top-level"* ]]
}

@test "check_shrink passes a same-size body and reports the new length" {
  run check_shrink "$ROOT/good.md" "$(file_length "$ROOT/good.md")" 0
  [[ "$status" -eq 0 ]]
  [[ "$output" == "$(file_length "$ROOT/good.md")" ]]
}

@test "check_shrink rejects a >50% reduction" {
  run check_shrink "$ROOT/good.md" 1000 0
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"shrink"* ]]
}

@test "check_shrink permits a >50% reduction under allow_shrink" {
  run check_shrink "$ROOT/good.md" 1000 1
  [[ "$status" -eq 0 ]]
}

# Regression: lengths once mixed jq `length` (characters) with wc -c (bytes), so em-dashes made the ratio meaningless.
@test "check_shrink measures both sides in bytes, so multibyte text cannot hide a shrink" {
  printf '# Map — dash\n\n%s\n' "$(head -c 400 /dev/zero | tr '\0' 'x')" >"$ROOT/multibyte.md"
  run check_shrink "$ROOT/good.md" "$(file_length "$ROOT/multibyte.md")" 0
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"shrink"* ]]
}

@test "file_length counts bytes, not characters" {
  printf '# Map — dash\n' >"$ROOT/dash.md"
  run file_length "$ROOT/dash.md"
  [[ "$output" == "15" ]]
}

@test "fetch_body writes the body on success" {
  stub_gh "# fetched body"
  run fetch_body 1 "$ROOT/out.md"
  [[ "$status" -eq 0 ]]
  [[ "$(cat "$ROOT/out.md")" == "# fetched body" ]]
}

@test "fetch_body fails when gh exits non-zero and creates no destination" {
  printf '#!/usr/bin/env bash\nexit 1\n' >"$ROOT/gh"
  chmod +x "$ROOT/gh"
  export PATH="$ROOT:$PATH"
  run fetch_body 1 "$ROOT/out.md"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"could not fetch"* ]]
  [[ ! -e "$ROOT/out.md" ]]
}

@test "fetch_body fails on an empty body rather than snapshotting nothing" {
  stub_gh ""
  run fetch_body 1 "$ROOT/out.md"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"came back empty"* ]]
  [[ ! -e "$ROOT/out.md" ]]
}

@test "backup_path is XDG-scoped and stamped" {
  run backup_path 42
  [[ "$output" == "$ROOT/state/dotfiles/issue-backups/issue-42-"*".md" ]]
}

@test "cmd_push refuses an empty body before touching the network" {
  stub_gh "# previous"
  run cmd_push 1 "$ROOT/empty.md"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"is empty"* ]]
  [[ ! -s "$GH_LOG" ]]
}

@test "cmd_push snapshots, diffs and publishes" {
  stub_gh "# previous
"
  run cmd_push 7 "$ROOT/good.md"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Snapshot: $ROOT/state/dotfiles/issue-backups/issue-7-"* ]]
  [[ "$output" == *"Body length: 11 -> 27 bytes"* ]]
  [[ "$output" == *"Published #7"* ]]
  grep -q "^edited 7$" "$GH_LOG"
}

@test "cmd_push aborts at the prompt when confirmation is declined" {
  stub_gh "# previous
"
  export ASSUME_YES=0
  run cmd_push 7 "$ROOT/good.md" <<< "n"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"Aborted."* ]]
  [[ ! -s "$GH_LOG" ]]
}

@test "cmd_push aborts when no snapshot can be taken" {
  export GH_LOG="$ROOT/calls.log"
  : >"$GH_LOG"
  printf '#!/usr/bin/env bash\nexit 1\n' >"$ROOT/gh"
  chmod +x "$ROOT/gh"
  export PATH="$ROOT:$PATH"
  run cmd_push 7 "$ROOT/good.md"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"without a restorable snapshot"* ]]
  [[ ! -s "$GH_LOG" ]]
}

@test "cmd_push requires both an issue and a file" {
  run cmd_push 1
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"Usage:"* ]]
}

@test "cmd_push rejects an unknown flag" {
  run cmd_push 1 "$ROOT/good.md" --bogus
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"unknown flag"* ]]
}
