# === Proxmox ===

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
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
    ip          = string  # CIDR, e.g. "10.0.10.11/24"
    storage_ip  = string  # same here
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
