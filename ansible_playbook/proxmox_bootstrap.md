# Proxmox OpenTofu bootstrap

Recreates the `terraform@pve` user, `Terraform` role, ACL, and `provider` API
token that OpenTofu uses to deploy VMs on the Proxmox host. Run it from a
clean host after a total loss; it needs no existing Proxmox credential because
it runs on-host as root through `pveum`.

The `Terraform` role only covers what the New-H0Ryzen deploy needs: VM
create/manage, cloud-init, local LVM storage, and GPU/USB passthrough via
hardware mappings. `User.Modify` is off-limits so the token can't grant itself
more rights.

## Run

Controller needs `ansible` and root SSH access to the Proxmox host.

```
cp inventory.proxmox.example inventory.proxmox
# edit inventory.proxmox: set the host address
ansible-playbook -i inventory.proxmox proxmox_bootstrap.yml
```

The first run prints the token secret once. Store it in a secret manager,
never in this repo. Later runs are no-ops.

## Rotating a lost secret

If the secret is lost and the token still exists, force a fresh one. The
playbook removes the existing token, then creates a new one and prints its
secret.

```
ansible-playbook -i inventory.proxmox proxmox_bootstrap.yml \
  -e regenerate_provider_token=true
```

## What gets created

| Item | Value |
| --- | --- |
| User | `terraform@pve` |
| Role | `Terraform` |
| ACL | `/` bound to `terraform@pve` with `Terraform` |
| Token | `provider`, `--privsep 0`, inheriting the scoped role |

Verify with `pveum user permissions terraform@pve`.