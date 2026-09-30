resource "proxmox_storage_directory" "local" {
  id   = "local"
  path = "/var/lib/vz"

  # import is what the disk image uploads as; PVE replaces the list whole, so anything undeclared is dropped.
  content = ["backup", "import", "iso", "vztmpl"]
}
