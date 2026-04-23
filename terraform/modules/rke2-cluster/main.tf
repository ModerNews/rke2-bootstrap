locals {
  vm_defaults = {
    os_type            = "cloud-init"
    start_at_node_boot = true
    agent              = 1
    full_clone         = true
    timeout            = "10m"
  }
}

# === Masters ===

resource "proxmox_vm_qemu" "master" {
  for_each = var.control_plane_nodes

  vmid        = each.value.vmid
  name        = each.key
  target_node = each.value.target_node

  clone              = var.master_profile.clone
  os_type            = local.vm_defaults.os_type
  memory             = var.master_profile.memory
  cpu {
    cores = var.master_profile.cores
  }
  start_at_node_boot = local.vm_defaults.start_at_node_boot
  agent              = local.vm_defaults.agent
  full_clone         = local.vm_defaults.full_clone

  timeouts {
    create = local.vm_defaults.timeout
    update = local.vm_defaults.timeout
    delete = local.vm_defaults.timeout
  }

  disks {
    virtio {
      virtio0 {
        disk {
          storage = var.master_os_pool
          size    = var.master_profile.disk_size
        }
      }
      virtio1 {
        disk {
          storage = var.master_etcd_pool
          size    = var.master_profile.etcd_disk_size
        }
      }
      virtio2 {
        disk {
          storage = var.master_os_pool
          size    = var.master_profile.log_disk_size
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = var.master_os_pool
        }
      }
    }
  }

  network {
    id     = 0
    bridge = var.cluster_bridge
    model  = "virtio"
  }
  network {
    id     = 1
    bridge = var.storage_bridge
    tag    = var.storage_vlan
    model  = "virtio"
  }

  ipconfig0    = "ip=${each.value.ip},gw=${var.gateway}"
  ipconfig1    = "ip=${each.value.storage_ip}"
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  cicustom     = "user=cephfs:snippets/user-data-rke2-master.yaml"

  tags = "terraform,alma,rke2,master,${var.cluster_name}"
}

# === Workers ===

resource "proxmox_vm_qemu" "worker" {
  for_each = var.worker_nodes

  vmid        = each.value.vmid
  name        = each.key
  target_node = each.value.target_node

  clone              = var.worker_profile.clone
  os_type            = local.vm_defaults.os_type
  memory             = var.worker_profile.memory
  cpu {
    cores = var.worker_profile.cores
  }
  start_at_node_boot = local.vm_defaults.start_at_node_boot
  agent              = local.vm_defaults.agent
  full_clone         = local.vm_defaults.full_clone

  timeouts {
    create = local.vm_defaults.timeout
    update = local.vm_defaults.timeout
    delete = local.vm_defaults.timeout
  }

  disks {
    virtio {
      virtio0 {
        disk {
          storage = var.worker_os_pool
          size    = var.worker_profile.disk_size
        }
      }
      virtio1 {
        disk {
          storage = var.worker_os_pool
          size    = var.worker_profile.log_disk_size
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = var.worker_os_pool
        }
      }
    }
  }

  network {
    id     = 0
    bridge = var.cluster_bridge
    model  = "virtio"
  }
  network {
    id     = 1
    bridge = var.storage_bridge
    tag    = var.storage_vlan
    model  = "virtio"
  }

  ipconfig0    = "ip=${each.value.ip},gw=${var.gateway}"
  ipconfig1    = "ip=${each.value.storage_ip}"
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  cicustom     = "user=cephfs:snippets/user-data-rke2-worker.yaml"

  tags = "terraform,alma,rke2,worker,${var.cluster_name}"
}
