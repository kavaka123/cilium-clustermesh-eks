# ClusterMesh Module Outputs

output "clustermesh_enabled" {
  description = "Whether ClusterMesh is enabled"
  value       = var.enable_clustermesh
}

output "clustermesh_service_ip" {
  description = "External IP of ClusterMesh API server service"
  value       = var.enable_clustermesh && var.expose_clustermesh_service && length(data.kubernetes_service.clustermesh_apiserver_external) > 0 ? try(data.kubernetes_service.clustermesh_apiserver_external[0].status[0].load_balancer[0].ingress[0].ip, "") : ""
}

output "clustermesh_service_hostname" {
  description = "External hostname of ClusterMesh API server service"
  value       = var.enable_clustermesh && var.expose_clustermesh_service && length(data.kubernetes_service.clustermesh_apiserver_external) > 0 ? try(data.kubernetes_service.clustermesh_apiserver_external[0].status[0].load_balancer[0].ingress[0].hostname, "") : ""
}

output "cluster_name" {
  description = "Name of the cluster"
  value       = var.cluster_name
}

output "cluster_id" {
  description = "Cluster ID used for ClusterMesh"
  value       = var.cluster_id
}

output "cluster_context" {
  description = "Kubernetes context for this cluster"
  value       = var.cluster_context
}
