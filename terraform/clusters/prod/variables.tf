# === Proxmox ===

variable "proxmox_api_url" {
  type = string
}

variable "vault_addr" {
  type    = string
  default = "https://api.vault.internal.wmsdev.pl:8200"
}

# === Generics ===

variable "nameserver" {
  type = string
}

variable "searchdomain" {
  type    = string
  default = "internal.wmsdev.pl"
}

variable "gateway" {
  type        = string
  description = "Default gateway for the cluster network"
}

variable "master_os_pool" {
  type = string
}

variable "master_etcd_pool" {
  type        = string
  description = "Fast pool for etcd — use SSD-backed storage"
}

variable "worker_os_pool" {
  type = string
}

# === Node definitions ===

variable "control_plane_nodes" {
  type = map(object({
    vmid        = number
    target_node = string
    ip          = string
    storage_ip  = string
  }))
}

variable "worker_nodes" {
  type = map(object({
    vmid        = number
    target_node = string
    ip          = string
    storage_ip  = string
  }))
}
