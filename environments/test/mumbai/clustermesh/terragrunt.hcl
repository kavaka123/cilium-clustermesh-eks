# ClusterMesh Terragrunt Configuration for Mumbai

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/clustermesh"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name = "eks-mumbai"
    cluster_id   = "1"
  }
}

dependency "cilium" {
  config_path = "../../singapore/cilium"

  mock_outputs = {
    cluster_id                          = "2"
    cluster_name                        = "eks-singapore"
    clustermesh_apiserver_endpoint      = "https://mock.clustermesh.apiserver:2379"
    clustermesh_apiserver_remote_cacrt  = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t"
    clustermesh_apiserver_remote_tlscrt = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t"
    clustermesh_apiserver_remote_tlskey = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t"
  }
}

# Generate provider configuration for Mumbai region
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
  
  default_tags {
    tags = {
      Project     = "cilium-clustermesh"
      Environment = "test"
      Owner       = "devops-team"
      Region      = "ap-south-1"
      ManagedBy   = "terragrunt"
      Component   = "cilium"
      Cluster     = "mumbai"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = "${dependency.eks.outputs.cluster_name}"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "${dependency.eks.outputs.cluster_name}"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

EOF
}

# Inputs
inputs = {
  # Cluster configuration
  cluster_name                        = dependency.cilium.outputs.cluster_name
  cluster_id                          = dependency.cilium.outputs.cluster_id
  clustermesh_apiserver_endpoint      = dependency.cilium.outputs.clustermesh_apiserver_endpoint
  clustermesh_apiserver_remote_cacrt  = dependency.cilium.outputs.clustermesh_apiserver_remote_cacrt
  clustermesh_apiserver_remote_tlscrt = dependency.cilium.outputs.clustermesh_apiserver_remote_tlscrt
  clustermesh_apiserver_remote_tlskey = dependency.cilium.outputs.clustermesh_apiserver_remote_tlskey
}
