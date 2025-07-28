# ClusterMesh Terragrunt Configuration for Singapore

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/clustermesh"
}

# Dependencies
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock1", "subnet-mock2"]
  }
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name                       = "singapore-cluster"
    cluster_id                         = "singapore-cluster"
    cluster_endpoint                   = "https://mock.eks.amazonaws.com"
    cluster_certificate_authority_data = "mock-cert"
    oidc_issuer_url                    = "https://oidc.eks.mock.amazonaws.com/id/mock"
  }
}

dependency "cilium" {
  config_path = "../cilium"

  mock_outputs = {
    cilium_installed = true
  }
}

# Inputs
inputs = {
  # Cluster configuration
  cluster_name    = dependency.eks.outputs.cluster_name
  cluster_id      = 2 # Singapore cluster ID
  cluster_context = "singapore-cluster"

  # ClusterMesh configuration
  enable_clustermesh         = true
  expose_clustermesh_service = true
  create_manual_config       = false
  install_cilium_cli         = true

  # Peer cluster (Mumbai)
  peer_cluster_context = "" # Will be set manually when connecting

  # Kubeconfig
  kubeconfig_path = "~/.kube/config"

  # Dependencies
  cilium_ready_dependency = dependency.cilium.outputs

  # Tags
  tags = {
    Environment = "test"
    Region      = "singapore"
    Purpose     = "clustermesh"
    ManagedBy   = "terragrunt"
  }
}
