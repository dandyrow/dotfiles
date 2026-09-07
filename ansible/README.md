# Ansible

Ansible content for this repo. `proxmox.yml` bootstraps the least-privilege
Proxmox user OpenTofu uses to deploy VMs.

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

### Run

Controller needs `ansible` (bundles `community.proxmox`), or `ansible-core`
plus `ansible-galaxy collection install -r requirements.yml`. Auth comes from
environment variables resolved via `lookup('env', ...)`; the collection marks
`api_password` `no_log`, so the root password is masked in all output including
`-vvv`.

```
cd ansible
export PROXMOX_HOST=https://pve.example.net:8006
export PROXMOX_USER=root@pam
read -rs PROXMOX_PASSWORD   # silent read keeps the root password out of shell history
export PROXMOX_PASSWORD
export PROXMOX_VALIDATE_CERTS=false   # only needed if the node cert isn't trusted yet
ansible-playbook proxmox.yml
```

The first run prints the token secret once. Store it in a secret manager,
never in this repo. Later runs are no-ops.

### Rotating a lost secret

If the secret is lost and the token still exists, force a fresh one with the
same env vars as above plus the regenerate flag. The playbook drops the
user's tokens (this user only ever has `provider`), then mints a new one and
prints its secret.

```
cd ansible
ansible-playbook proxmox.yml -e proxmox_bootstrap_regenerate_token=true
```

### What gets created

| Item | Value |
| --- | --- |
| User | `terraform@pve` |
| Role | `Terraform` |
| ACL | `/` bound to `terraform@pve` with `Terraform` |
| Token | `provider`, `privsep: false`, inheriting the scoped role |

Verify with `pveum user permissions terraform@pve` on the host.
