proxmox_api_url = "https://10.0.0.10:8006/api2/json"

nameserver   = "10.0.0.1"
searchdomain = "wmsdev.pl"
gateway      = "10.1.2.1"

master_os_pool   = "ceph"
master_etcd_pool = "local-lvm"
worker_os_pool   = "ceph"

control_plane_nodes = {
  K8sToolsMasterRKE-1 = { vmid = 201, target_node = "hades",  ip = "10.1.2.11/24", storage_ip = "10.0.10.111/24" }
  K8sToolsMasterRKE-2 = { vmid = 202, target_node = "athena", ip = "10.1.2.12/24", storage_ip = "10.0.10.112/24" }
  K8sToolsMasterRKE-3 = { vmid = 203, target_node = "zeus",   ip = "10.1.2.13/24", storage_ip = "10.0.10.113/24" }
}

worker_nodes = {
  K8sToolsWorkerRKE-1 = { vmid = 211, target_node = "hades",  ip = "10.1.2.21/24", storage_ip = "10.0.10.121/24" }
  K8sToolsWorkerRKE-2 = { vmid = 212, target_node = "athena", ip = "10.1.2.22/24", storage_ip = "10.0.10.122/24" }
  K8sToolsWorkerRKE-3 = { vmid = 213, target_node = "zeus",   ip = "10.1.2.23/24", storage_ip = "10.0.10.123/24" }
}
