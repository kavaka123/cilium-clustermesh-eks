# Cilium Module Outputs
output "cluster_name" {
  description = "Name of the cluster where Cilium is installed"
  value       = var.cluster_name
}

output "cluster_id" {
  description = "Cluster ID used for ClusterMesh"
  value       = var.cluster_id
}
