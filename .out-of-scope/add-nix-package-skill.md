# `add-nix-package` skill extraction

The propose-a-config-edit path in the machine-global `nix-native-deps.md`
guidance was considered for extraction into a repo-local `add-nix-package`
skill. The current setup is kept as-is.

## Why this is out of scope

The acting mechanics are only ~10 lines of a 60-line doc: scope-routing,
closest-sibling placement, and the dedicated-branch PR. That resident
context cost in every repo is trivial for a path exercised almost never.

Extraction would buy single-sourcing symmetry with the `bump-nix-package`
and `nix-workflow` skills, but at real cost:

- The "not in `~/.dotfiles` → surface only" guard must stay resident
  regardless, so the always-on savings are only the in-dotfiles branch.
- Split-brain risk: doc-gate and skill-mechanics can drift apart, and the
  preserved guard is precisely what the extraction depends on.
- It touches a machine-global doc (loaded via `instructions` by opencode
  and via the copilot-instructions symlink) for marginal gain; any edit
  there carries blast radius across every repo.

Nothing is broken by deferring. If the skill graph is later consolidated,
revisit this with the copilot scoping decision from #103 in hand.

## Prior requests

- #106: "Extract the propose-a-config-edit path into an `add-nix-package` skill"