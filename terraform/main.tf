terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = true
}

# === Masters ===

resource "proxmox_vm_qemu" "master" {
  for_each = var.control_plane_nodes

  vmid        = each.value.vmid
  name        = each.key
  target_node = each.value.target_node

  clone       = local.node_profile.master.clone
  os_type     = local.vm_defaults.os_type
  memory = local.node_profile.master.memory
  cpu {
    cores = local.node_profile.master.cores
  }
  start_at_node_boot = local.vm_defaults.start_at_node_boot
  agent       = local.vm_defaults.agent
  full_clone  = local.vm_defaults.full_clone

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
          size    = local.node_profile.master.disk_size
        }
      }
      virtio1 {
        disk {
          storage = var.master_etcd_pool
          size    = local.node_profile.master.etcd_disk_size
        }
      }
      virtio2 {
        disk {
          storage = var.master_os_pool
          size    = local.node_profile.master.log_disk_size
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
    bridge = local.vm_defaults.cluster_bridge
    model  = "virtio"
  }
  network {
    id     = 1
    bridge = local.vm_defaults.storage_bridge
    tag    = local.vm_defaults.storage_vlan
    model  = "virtio"
  }

  ipconfig0    = "ip=${each.value.ip},gw=${var.gateway}"
  ipconfig1    = "ip=${each.value.storage_ip}"
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  cicustom     = "user=cephfs:snippets/user-data-rke2-master.yaml"

  tags = "terraform,alma,rke2,master,tools"
}

# === Workers ===

resource "proxmox_vm_qemu" "worker" {
  for_each = var.worker_nodes

  vmid        = each.value.vmid
  name        = each.key
  target_node = each.value.target_node

  clone       = local.node_profile.worker.clone
  os_type     = local.vm_defaults.os_type
  memory = local.node_profile.worker.memory
  cpu {
    cores = local.node_profile.worker.cores
  }
  start_at_node_boot = local.vm_defaults.start_at_node_boot
  agent       = local.vm_defaults.agent
  full_clone  = local.vm_defaults.full_clone

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
          size    = local.node_profile.worker.disk_size
        }
      }
      virtio1 {
        disk {
          storage = var.worker_os_pool
          size    = local.node_profile.worker.log_disk_size
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
    bridge = local.vm_defaults.cluster_bridge
    model  = "virtio"
  }
  network {
    id     = 1
    bridge = local.vm_defaults.storage_bridge
    tag    = local.vm_defaults.storage_vlan
    model  = "virtio"
  }

  ipconfig0    = "ip=${each.value.ip},gw=${var.gateway}"
  ipconfig1    = "ip=${each.value.storage_ip}"
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  cicustom     = "user=cephfs:snippets/user-data-rke2-worker.yaml"

  tags = "terraform,alma,rke2,worker,tools"
}
