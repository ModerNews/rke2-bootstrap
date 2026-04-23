locals {
  vm_defaults = {
    cluster_bridge = "k8sdev"
    storage_bridge = "vmbr0"
    storage_vlan   = 99
  }

  node_profile = {
    master = {
      clone          = "Alma"
      memory         = 16384
      cores          = 6
      disk_size      = "20G"
      etcd_disk_size = "10G"
      log_disk_size  = "10G"
    }
    worker = {
      clone         = "Alma"
      memory        = 24576
      cores         = 8
      disk_size     = "20G"
      log_disk_size = "10G"
    }
  }
}
