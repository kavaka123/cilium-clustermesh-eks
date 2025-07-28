# Cilium Module Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_id" {
  description = "Unique identifier for the cluster (used for ClusterMesh)"
  type        = number
  validation {
    condition     = var.cluster_id >= 1 && var.cluster_id <= 255
    error_message = "Cluster ID must be between 1 and 255."
  }
}

variable "region" {
  description = "AWS region where the cluster is deployed"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  type        = string
}

variable "cilium_version" {
  description = "Version of Cilium to install"
  type        = string
  default     = "1.17.6"
}

variable "clustermesh_enabled" {
  description = "Enable ClusterMesh for multi-cluster communication"
  type        = bool
  default     = false
}

variable "hubble_enabled" {
  description = "Enable Hubble for network observability"
  type        = bool
  default     = true
}

variable "hubble_ui_enabled" {
  description = "Enable Hubble UI"
  type        = bool
  default     = false
}

variable "policy_enforcement_mode" {
  description = "Policy enforcement mode: default, always, never"
  type        = string
  default     = "default"
  validation {
    condition     = contains(["default", "always", "never"], var.policy_enforcement_mode)
    error_message = "Policy enforcement mode must be one of: default, always, never."
  }
}

variable "node_selector" {
  description = "Node selector for Cilium pods"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
