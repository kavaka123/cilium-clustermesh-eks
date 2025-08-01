# Mumbai Cilium Terragrunt Configuration

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/cilium"
}

# Dependencies - ensure EKS cluster is created first
dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_id                         = "1"
    cluster_name                       = "eks-mumbai"
    cluster_endpoint                   = "https://mock.eks.amazonaws.com"
    cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t"
    oidc_issuer_url                    = "https://oidc.eks.ap-south-1.amazonaws.com/id/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# VPC dependency for private subnet IDs
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    private_subnet_ids = ["subnet-12345", "subnet-67890"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
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
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.2"
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

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
EOF
}

inputs = {
  # Basic Configuration
  cluster_name = dependency.eks.outputs.cluster_name
  cluster_id   = 1
  region       = "ap-south-1"


  # Cilium Configuration
  cilium_version    = "1.15.4"
  hubble_enabled    = true
  hubble_ui_enabled = true

  tags = {
    Project     = "cilium-clustermesh"
    Environment = "test"
    Component   = "cilium"
    Cluster     = "mumbai"
  }
}
