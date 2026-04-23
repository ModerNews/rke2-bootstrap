output "master_ips" {
  value = { for name, node in var.control_plane_nodes : name => node.ip }
}

output "worker_ips" {
  value = { for name, node in var.worker_nodes : name => node.ip }
}
