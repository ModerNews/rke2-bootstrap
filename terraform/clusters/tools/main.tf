terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

provider "vault" {
  address = var.vault_addr
  # token read from VAULT_TOKEN env var
}

data "vault_kv_secret_v2" "proxmox" {
  mount = "secret"
  name  = "terraform/proxmox"
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = data.vault_kv_secret_v2.proxmox.data["token_id"]
  pm_api_token_secret = data.vault_kv_secret_v2.proxmox.data["token_secret"]
  pm_tls_insecure     = true
}

module "cluster" {
  source = "../../modules/rke2-cluster"

  cluster_name   = "tools"
  cluster_bridge = local.vm_defaults.cluster_bridge
  storage_bridge = local.vm_defaults.storage_bridge
  storage_vlan   = local.vm_defaults.storage_vlan

  gateway      = var.gateway
  nameserver   = var.nameserver
  searchdomain = var.searchdomain

  master_os_pool   = var.master_os_pool
  master_etcd_pool = var.master_etcd_pool
  worker_os_pool   = var.worker_os_pool

  master_profile = local.node_profile.master
  worker_profile = local.node_profile.worker

  control_plane_nodes = var.control_plane_nodes
  worker_nodes        = var.worker_nodes
}

output "master_ips" { value = module.cluster.master_ips }
output "worker_ips" { value = module.cluster.worker_ips }
