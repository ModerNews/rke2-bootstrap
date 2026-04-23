proxmox_api_url = "https://10.0.0.10:8006/api2/json"

nameserver   = "10.0.0.1"
searchdomain = "wmsdev.pl"
gateway      = "10.1.1.1"

master_os_pool   = "ceph"
master_etcd_pool = "local-lvm"
worker_os_pool   = "ceph"

control_plane_nodes = {
  K8sProdMasterRKE-1 = { vmid = 301, target_node = "hades",  ip = "10.1.1.11/24", storage_ip = "10.0.10.211/24" }
  K8sProdMasterRKE-2 = { vmid = 302, target_node = "athena", ip = "10.1.1.12/24", storage_ip = "10.0.10.212/24" }
  K8sProdMasterRKE-3 = { vmid = 303, target_node = "zeus",   ip = "10.1.1.13/24", storage_ip = "10.0.10.213/24" }
}

worker_nodes = {
  K8sProdWorkerRKE-1 = { vmid = 311, target_node = "hades",  ip = "10.1.1.21/24", storage_ip = "10.0.10.221/24" }
  K8sProdWorkerRKE-2 = { vmid = 312, target_node = "athena", ip = "10.1.1.22/24", storage_ip = "10.0.10.222/24" }
  K8sProdWorkerRKE-3 = { vmid = 313, target_node = "zeus",   ip = "10.1.1.23/24", storage_ip = "10.0.10.223/24" }
}
