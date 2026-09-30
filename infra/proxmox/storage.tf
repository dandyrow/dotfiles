resource "proxmox_storage_directory" "local" {
  id   = "local"
  path = "/var/lib/vz"

  # PVE's default for local (iso,vztmpl,backup) plus import, which the disk image uploads as.
  # PVE replaces the list whole, so anything on the node but absent here is dropped.
  content = ["backup", "import", "iso", "vztmpl"]
}
