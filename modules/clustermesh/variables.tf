# ClusterMesh Module Variables

variable "enable_clustermesh" {
  description = "Enable ClusterMesh for this cluster"
  type        = bool
  default     = true
}

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

variable "cluster_context" {
  description = "Kubernetes context name for this cluster"
  type        = string
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "peer_cluster_context" {
  description = "Kubernetes context name for peer cluster to connect to"
  type        = string
  default     = ""
}

variable "expose_clustermesh_service" {
  description = "Expose ClusterMesh API server via LoadBalancer service"
  type        = bool
  default     = true
}

variable "create_manual_config" {
  description = "Create manual configuration secret for ClusterMesh"
  type        = bool
  default     = false
}

variable "install_cilium_cli" {
  description = "Install Cilium CLI if not available"
  type        = bool
  default     = true
}

variable "cilium_ready_dependency" {
  description = "Dependency to ensure Cilium is ready before enabling ClusterMesh"
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
