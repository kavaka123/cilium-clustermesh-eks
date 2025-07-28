# Cilium Module Outputs

output "cilium_release_name" {
  description = "Name of the Cilium Helm release"
  value       = helm_release.cilium.name
}

output "cilium_release_version" {
  description = "Version of the Cilium Helm release"
  value       = helm_release.cilium.version
}

output "cilium_namespace" {
  description = "Namespace where Cilium is installed"
  value       = helm_release.cilium.namespace
}

output "cluster_name" {
  description = "Name of the cluster where Cilium is installed"
  value       = var.cluster_name
}

output "cluster_id" {
  description = "Cluster ID used for ClusterMesh"
  value       = var.cluster_id
}

output "clustermesh_enabled" {
  description = "Whether ClusterMesh is enabled"
  value       = var.clustermesh_enabled
}
