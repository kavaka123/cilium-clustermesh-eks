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

output "clustermesh_apiserver_endpoint" {
  description = "API server endpoint for ClusterMesh"
  value       = "https://${data.kubernetes_service.cilium_clustermesh_apiserver.status.0.load_balancer.0.ingress.0.hostname}:2379"
}

output "clustermesh_apiserver_remote_cacrt" {
  description = "CA certificate for the remote ClusterMesh API server"
  value       = data.kubernetes_secret.cilium_clustermesh_remote_cert.binary_data["ca.crt"]
  sensitive   = true
}

output "clustermesh_apiserver_remote_tlscrt" {
  description = "TLS certificate for the remote ClusterMesh API server"
  value       = data.kubernetes_secret.cilium_clustermesh_remote_cert.binary_data["tls.crt"]
  sensitive   = true
}

output "clustermesh_apiserver_remote_tlskey" {
  description = "TLS key for the remote ClusterMesh API server"
  value       = data.kubernetes_secret.cilium_clustermesh_remote_cert.binary_data["tls.key"]
  sensitive   = true
}