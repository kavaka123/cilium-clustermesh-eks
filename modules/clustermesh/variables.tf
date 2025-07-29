# ClusterMesh Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_id" {
  description = "Unique cluster ID for ClusterMesh (1-255)"
  type        = number
  validation {
    condition     = var.cluster_id >= 1 && var.cluster_id <= 255
    error_message = "Cluster ID must be between 1 and 255."
  }
}

variable "clustermesh_apiserver_endpoint" {
  description = "API server endpoint for ClusterMesh"
  type        = string
}

variable "clustermesh_apiserver_remote_cacrt" {
  description = "CA certificate for the remote ClusterMesh API server"
  type        = string
}

variable "clustermesh_apiserver_remote_tlscrt" {
  description = "TLS certificate for the remote ClusterMesh API server"
  type        = string
}

variable "clustermesh_apiserver_remote_tlskey" {
  description = "TLS key for the remote ClusterMesh API server"
  type        = string
}