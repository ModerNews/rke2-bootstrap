locals {
  vm_defaults = {
    os_type    = "cloud-init"
    start_at_node_boot = true
    agent      = 1
    full_clone = true
    timeout    = "10m"

    cluster_bridge = "k8stools"
    storage_bridge = "vmbr0"
    storage_vlan   = 99
  }

  node_profile = {
    master = {
      clone          = "alma"
      memory         = 8192
      cores          = 4
      disk_size      = "20G"
      etcd_disk_size = "10G"
      log_disk_size  = "10G"
    }
    worker = {
      clone         = "alma"
      memory        = 16384
      cores         = 8
      disk_size     = "20G"
      log_disk_size = "10G"
    }
  }
}
