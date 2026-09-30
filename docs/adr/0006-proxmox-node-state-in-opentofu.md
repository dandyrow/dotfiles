# The Proxmox node's declarative state lives in OpenTofu, not the Ansible bootstrap

The Proxmox node's configuration is declared in OpenTofu, starting with the
`local` datastore. The Ansible bootstrap keeps the job it already does well,
standing up the host and delivering the token, and shrinks rather than grows.

`import` is the one addition to `local`. The New-H0Ryzen deploy uploads its disk
image with `content_type = "import"`, and Proxmox accepts that only on a
datastore whose content list includes it. The PVE default for `local` is
`iso,vztmpl,backup` and leaves it out, so the default rejects the disk the deploy
depends on. `local` is also the only local datastore that can take it, since a
`lvmthin` store carries `images` and `rootdir` and nothing else.

The content list is written out in full rather than patched. Proxmox replaces the
list instead of merging it, which makes the declaration the list: any type added
to the node by hand and left out here is removed on the next apply. `snippets` is
the one people reach for, and it is not declared.

State stays local and out of the repo, and the live node is the source of truth.
`terraform.tfstate` holds the cloud-init password hash, and an import rebuilds
the state from the node anyway, so there is nothing in it worth the risk of
committing or the ceremony of backing up. After a total loss the VM is
recreated from its declaration rather than imported, because an import adopts
whatever the node holds as the new baseline, drift included. The one import that
does exist adopts `local` itself, so apply does not try to create a datastore the
installer already made. Where the state file eventually lives is
[#247](https://github.com/dandyrow/dotfiles/issues/247).

## Considered Options

**An Ansible role managing the datastore.** Built first and closed in
[#245](https://github.com/dandyrow/dotfiles/pull/245). The bpg provider ships a
resource for this, and the decision here is to hand node state to OpenTofu, so
writing the same resource in Ansible establishes a second mechanism to unwind
later. The attempt did settle a fact worth keeping: `community.proxmox` 2.0.0
cannot update an existing datastore. `proxmox_storage` only creates, and reports
an existing datastore as already present without touching it, so the role needed
a raw REST call for the one operation it existed to perform. `update` and
`dir_options` exist on unreleased `main` only, so pinning to the released module
would not have helped.

**Declaring the VM in the same step.** Rejected as scope. Storage is the first
resource because it is the first thing the deploy needs that the node's own
defaults get wrong. The VM is a separate piece of work.

**Adding `import` to `local-lvm` instead.** Rejected on the PVE side, not the
Terraform side. `lvmthin` accepts `images` and `rootdir`, so the content type
would have to go on a different datastore than the one the installer creates, and
the disk upload would target a store the deploy did not otherwise provision.

**Leaving the content list alone.** Rejected because it does not work. The
default is the reason the disk upload fails in the first place.

## Not decided here

Whether the VM itself is declared in OpenTofu, and which resources follow the
datastore, are open. So is the state backend, tracked in
[#247](https://github.com/dandyrow/dotfiles/issues/247); this ADR only fixes that
state is not committed and that the node decides what is true. The
`create_subdirs` argument is left unset on purpose, since an import adopts an
existing datastore and never creates one.
