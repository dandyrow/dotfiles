# The Proxmox node's configuration is declared in OpenTofu

Proxmox configuration that the API and the bpg provider can express is declared
in OpenTofu, under `infra/proxmox/`, and not in the Ansible bootstrap. The
bootstrap keeps what only it can do: install the host, mint the `terraform@pve`
user and its token, and grant the role. It should shrink, not grow a second
mechanism for the same node state.

Reaching for OpenTofu is the default for a new resource. Hand-setting something
on the node leaves nothing in the repo recording the requirement, and a reinstall
is exactly when that gets forgotten. The bootstrap is for what OpenTofu cannot
reach, such as minting the credential the provider token format depends on.

State stays local and out of the repo, and the live node is the source of truth.
`terraform.tfstate` holds the cloud-init password hash, and an import rebuilds
state from the node, so there is nothing in it worth committing and no backup
worth keeping. After a total loss, recreate a resource from its declaration
rather than importing it, because an import adopts whatever the node holds as
the new baseline, drift included. The one import that persists is for
installer-created storage, which cannot be recreated at all. Where the state file
eventually lives is [#247](https://github.com/dandyrow/dotfiles/issues/247).

The datastore content list is the first resource. Its specifics and the reasoning
behind them are in `infra/proxmox/README.md`, and they stay there: it is a settled
decision, so a pointer beats a second copy that can drift.

## Considered Options

**An Ansible role for the same configuration.** Built once, then closed in
[#245](https://github.com/dandyrow/dotfiles/pull/245). The bpg provider ships
resources for this, so an Ansible role means writing the same thing twice and
later unwinding one of them. It also hit a wall worth keeping: `community.proxmox`
2.0.0 cannot update an existing datastore. `proxmox_storage` only creates one and
reports an existing as already present, so the role needed a raw REST call for the
operation it existed to perform. `update` and `dir_options` are on unreleased
`main`.

**Declaring only what has no module equivalent.** Rejected. That rule would keep
Ansible as the default and make OpenTofu the exception, which is the arrangement
this decision exists to end.

## Not decided here

Which resources follow, the VM in particular. So is the state backend, tracked in
[#247](https://github.com/dandyrow/dotfiles/issues/247); this ADR only fixes that
state is not committed and that the node decides what is true.
