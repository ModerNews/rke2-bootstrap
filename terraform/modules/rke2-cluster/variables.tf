# === Proxmox / Network ===

variable "gateway" {
  type        = string
  description = "Default gateway for the cluster network"
}

variable "nameserver" {
  type = string
}

variable "searchdomain" {
  type    = string
  default = "internal.wmsdev.pl"
}

# === Networking ===

variable "cluster_bridge" {
  type        = string
  description = "Proxmox bridge for cluster traffic"
}

variable "storage_bridge" {
  type    = string
  default = "vmbr0"
}

variable "storage_vlan" {
  type    = number
  default = 99
}

# === Storage pools ===

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

# === Node profiles ===

variable "master_profile" {
  type = object({
    clone          = string
    memory         = number
    cores          = number
    disk_size      = string
    etcd_disk_size = string
    log_disk_size  = string
  })
}

variable "worker_profile" {
  type = object({
    clone         = string
    memory        = number
    cores         = number
    disk_size     = string
    log_disk_size = string
  })
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

# === Cluster identity ===

variable "cluster_name" {
  type        = string
  description = "Short name used in VM tags (e.g. 'tools', 'prod')"
}
