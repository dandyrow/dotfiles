# Ansible

Ansible content for this repo. `proxmox.yml` restores the Proxmox state the
New-H0Ryzen deploy depends on: the least-privilege user OpenTofu authenticates
as, and what the `local` datastore is allowed to hold.

## proxmox.yml bootstrap

Recreates the `terraform@pve` user, `Terraform` role, ACL, and `provider` API
token that OpenTofu uses to deploy VMs on the Proxmox host. Run it from a
clean host after a total loss; it authenticates to the Proxmox API as
`root@pam` for the one-time bootstrap. `root@pam` is recreated at every
install, so it survives a loss where a token-based credential would not.

The `Terraform` role only covers what the New-H0Ryzen deploy needs: VM
create/manage, cloud-init, local LVM storage, and GPU/USB passthrough via
hardware mappings. `User.Modify` is off-limits so the token can't grant itself
more rights.

The playbook has no SSH dependency: the `community.proxmox` modules drive the
API from the controller, the same transport the steady-state OpenTofu/bpg
provider will use.

### local datastore content

The deploy uploads the NixOS disk image as `content_type = "import"`, and Proxmox
only accepts that on a datastore whose content list includes it. `local` is the
only local datastore that can: `local-lvm` is a block-level `lvmthin` store whose
allowed content set is `images` and `rootdir` only, with no `import` in it, so no
amount of reconfiguring it gives the upload somewhere to land. The image is staged
on `local` and the VM's live disk is created on `local-lvm` by the import.

The list in `roles/proxmox_storage/defaults/main.yml` is `local`'s Proxmox default
plus `import`. It replaces the datastore's whole content list rather than merging
into it, so anything the node holds beyond what is declared is removed on the next
run. If `local` needs to carry more, add it there rather than on the node, or the
next total-loss recovery will drop it again.

`community.proxmox` is not used for this. At `2.0.0` `proxmox_storage` only ever
POSTs a new datastore, and one that already exists is reported as already present
and left alone, so it cannot express "add `import` to the storage the installer
already made". Update support is on the collection's `main` branch and not in a
release. The role therefore opens an API ticket and PUTs `/storage/local` itself,
sending the config digest so a concurrent edit fails rather than clobbers.

Adding a content type does not necessarily leave a directory behind it. `import`
maps to `/var/lib/vz/import` on `local`, and a host restored from a total loss may
not have it, since nothing in this play creates directories on the node. The first
image upload is where that surfaces; `mkdir -p /var/lib/vz/import` on the node if
it fails on write.

### Run

The controller needs `ansible-core`, the collection's Python runtime deps on
the interpreter that executes the module (`proxmoxer >= 2.3`, `requests`), and
the collection itself. The `ansible` metapackage alone does not provide those
Python libs. The root flake's `ansible` devShell supplies all three plus `bws`
— `community.proxmox` ships bundled with the env's Ansible (`>= 2.0.0`, so
nothing to install):

```
nix develop ..#ansible
```

`nix develop` spawns a nested bash subshell; pass your own shell to keep your
normal zsh prompt and config instead:

```
nix develop ..#ansible -c "$SHELL"
```

Non-NixOS controllers: install `ansible-core`, `proxmoxer` and `requests`,
`bws`, then `ansible-galaxy collection install -r requirements.yml`.

Auth comes from environment variables resolved via
`lookup('ansible.builtin.env', ...)`; the collection marks `api_password`
`no_log`, so the root password is masked in all output including `-vvv`. The
BWS bootstrap store is written the same way: the access token and project id
come from env vars in the same style, and the token write is masked via
`no_log`. The machine account backing `BWS_ACCESS_TOKEN` must have write
access to the project.

```
cd ansible
export PROXMOX_HOST=pve.example.net:8006
export PROXMOX_USER=root@pam
read -rs PROXMOX_PASSWORD   # silent read keeps the root password out of shell history
export PROXMOX_PASSWORD
export PROXMOX_VALIDATE_CERTS=false   # only needed if the node cert isn't trusted yet
export BWS_ACCESS_TOKEN=<write-enabled machine account token>
export BWS_PROJECT_ID=<homelab project id from bws project list>
ansible-playbook proxmox.yml -e ansible_python_interpreter=$(which python3)
```

The first run mints the token and auto-stores it into the BWS `homelab`
project in the same invocation (see the ADR in `docs/adr/`), so nothing is
captured or committed by hand. Later runs are no-ops.

### Rotating a lost secret

If the secret is lost and the token still exists, force a fresh one with the
same env vars as above plus the regenerate flag. The playbook drops the
user's tokens (this user only ever has `provider`), then mints a new one and
auto-stores the replacement in BWS the same way.

```
cd ansible
ansible-playbook proxmox.yml -e proxmox_bootstrap_regenerate_token=true -e ansible_python_interpreter=$(which python3)
```

### What gets created

| Item | Value |
| --- | --- |
| User | `terraform@pve` |
| Role | `Terraform` |
| ACL | `/` bound to `terraform@pve` with `Terraform` |
| Token | `provider`, `privsep: false`, inheriting the scoped role |
| Storage | `local` content set to `backup,import,iso,vztmpl` |

Verify with `pveum user permissions terraform@pve` on the host, and
`pvesm status --content import` for the datastore, which must list `local`.
