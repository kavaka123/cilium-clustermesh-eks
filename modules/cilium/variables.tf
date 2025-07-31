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


variable "cilium_version" {
  description = "Version of Cilium to install"
  type        = string
  default     = "1.18.0"
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

variable "ca_cert_path" {
  description = "Path to the CA certificate file for ClusterMesh"
  type        = string
  default     = ""
}

variable "ca_key_path" {
  description = "Path to the CA private key file for ClusterMesh"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
