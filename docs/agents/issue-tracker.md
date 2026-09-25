# Issue tracker: GitHub

Issues and PRDs for this repo are GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments by `jq` and fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v`. `gh` does this automatically when run inside a clone.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

The `wayfinder` skill maps an effort as a **map issue** (`wayfinder:map`) with **child tickets**. `gh` has no first-class sub-issue or dependency verbs, so these wire up through `gh api`, and the tracker UI then draws the frontier from the native edges. The `<n>/dependencies/*` endpoints are undocumented but functional as of `gh` 2.96 / 2026-07.

Both endpoints take the child's **database `id`** (integer), not its issue number, and must be passed with `-F` (typed) not `-f` (string), or the API returns `422 not of type integer`.

- **Get a ticket's database id**: `gh api repos/dandyrow/dotfiles/issues/<number> --jq .id`
- **Make a ticket a sub-issue of the map**:
  `gh api --method POST repos/dandyrow/dotfiles/issues/<map>/sub_issues -F sub_issue_id=<child_db_id>`
- **List a map's sub-issues**:
  `gh api repos/dandyrow/dotfiles/issues/<map>/sub_issues --jq '.[] | "#\(.number) [\(.state)] \(.title)"'`
- **Wire a blocking edge** (`<n>` is blocked by `<blocker>`):
  `gh api --method POST repos/dandyrow/dotfiles/issues/<n>/dependencies/blocked_by -F issue_id=<blocker_db_id>`
- **List what blocks a ticket**:
  `gh api repos/dandyrow/dotfiles/issues/<n>/dependencies/blocked_by --jq '.[] | "#\(.number) \(.title)"'`
- **Frontier query**: open `wayfinder:*` sub-issues that are unassigned and have no *open* blocker. There is no single query for "unblocked"; list the open children, then filter out any whose `blocked_by` list still contains an open issue:
  `gh issue list --label wayfinder:research --label wayfinder:grilling --state open --json number,title,assignees`
  then check each with the `blocked_by` list command above.

Claiming a ticket is `gh issue edit <n> --add-assignee @me`.

## Editing a map body

Never write a map body with a bare `gh issue edit <map> --body-file <file>`. GitHub keeps no revision history for issue bodies, so an overwrite is unrecoverable, and the two obvious shell idioms both fail open:

- `gh issue view <n> --json body > file` creates `file` before `gh` runs, so a failed fetch leaves a 0-byte file that a later `--body-file` happily publishes.
- Fetch and publish in separate commands means nothing stops the publish from reading a stale or truncated file.

Use `scripts/issue-body.sh`, which snapshots to XDG state, refuses an empty or headingless body, rejects a >50% length drop, shows a word diff, and asks before writing:

```bash
scripts/issue-body.sh fetch <map>              # prints the backup path
# edit that file with the read/edit tools, not shell redirection
scripts/issue-body.sh push <map> <file>        # snapshot, validate, diff, confirm, publish
```

`push` refuses to run if it cannot take a snapshot first. Pass `--allow-shrink` when a large deletion is intended, and `ASSUME_YES=1` to skip the prompt in automation.

Prefer the `read`/`edit`/`write` tools over shell redirection when editing a fetched body: `edit` fails loudly on a missing anchor, where a redirect cannot fail at all.
