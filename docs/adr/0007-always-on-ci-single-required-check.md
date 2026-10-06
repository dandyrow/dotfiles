# CI always runs and reports one required check, ci-ok

The `ci.yml` workflow has no path filter. Every PR and every push to `main`
starts a run, and a `changes` job decides what that run needs. It diffs against
the base branch on a PR, and treats everything as changed on a push or a manual
run, which is what the skills updater calls so its own PR gets a result. Nix
jobs gate on its output, so a docs-only PR runs almost nothing and still reports
one conclusion.

`ci-ok` is the only status check `main` requires. It runs with `if: always()`,
needs every other job, and passes when each of them either succeeded or was
skipped. A job with nothing to do cannot be wrong, so skipped counts as green.
Build jobs join its `needs` list as they land, and nothing else reports to
branch protection.

The build strategy behind those jobs:

Every Nix PR builds the risky derivations, the packages the overlay defines and
the nvidia driver
([#257](https://github.com/dandyrow/dotfiles/issues/257)). Those are the ones a
nixpkgs bump breaks, and this repo builds them itself, so upstream caches do not
cover them.

Full host toplevel builds run only on `flake.lock` PRs
([#258](https://github.com/dandyrow/dotfiles/issues/258)). A cold toplevel build
measured 10 to 28 minutes per host, which is a lot to ask of every PR. Nobody
waits on a dependency bump, so that is where the time goes. A `flake.lock` PR
is also the one PR where a green run means every host builds.

Dependabot's grouped `flake-inputs` PR merges itself once `ci-ok` is green
([#259](https://github.com/dandyrow/dotfiles/issues/259)). Merging deploys
nothing. Each machine changes only when the maintainer runs
`nixos-rebuild switch`, and that switch is the real gate on a bump.

Workflows use `GITHUB_TOKEN` and work around what it cannot do. Merges and PRs
made with it do not trigger `push` or `pull_request` runs, so a nightly
cache-warm run keeps the build cache fresh for merges that pass silently, and
the skills updater calls `workflow_dispatch` on its branch
([#260](https://github.com/dandyrow/dotfiles/issues/260)).

## Considered Options

**Keep the path filter on the workflow.** Rejected. A required check that never
starts is a PR that can never merge, and the filter skipped exactly the quiet
PRs that would have gone green.

**Require each job rather than a single `ci-ok`.** Rejected. A skipped matrix
job reports under its bare job name with no matrix suffix, so a required
per-host check would wait forever for a name GitHub never reports. One
aggregate check is what hides the matrix.

**Build every host toplevel on every Nix PR.** Rejected on the cold-build times
above.

**Replace `GITHUB_TOKEN` with a GitHub App.** Rejected. It gives back the events
`GITHUB_TOKEN` swallows, and pays for them with a long-lived private key held
twice, as an Actions secret and a Dependabot secret. A nightly run and a
dispatch call are cheaper than a credential with a rotation story.

**Review every dependency bump by hand.** Rejected. On a `flake-inputs` PR a
green `ci-ok` has already built all three hosts, and the deployment switch
still sits in front of the change, so a review pass adds a reading step and no
protection.

## Not decided here

Which derivations the risky build covers, and how the host matrix gets its list.
Both land with [#257](https://github.com/dandyrow/dotfiles/issues/257) and
[#258](https://github.com/dandyrow/dotfiles/issues/258). The auto-merge and
updater workflows are
[#259](https://github.com/dandyrow/dotfiles/issues/259) and
[#260](https://github.com/dandyrow/dotfiles/issues/260). Adding `ci-ok` to
`main`'s branch protection is the maintainer's change, made once `ci-ok` has
reported on `main`.
