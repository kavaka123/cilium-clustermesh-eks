# Mumbai EKS Terragrunt Configuration

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/eks"
}

# Dependencies - ensure VPC is created first
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                    = "vpc-12345678"
    private_subnet_ids        = ["subnet-12345678", "subnet-87654321"]
    cluster_security_group_id = "sg-12345678"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "peer_vpc" {
  config_path = "../../singapore/vpc"

  mock_outputs = {
    vpc_cidr_block = "10.21.0.0/16"
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
      Component   = "eks"
      Cluster     = "mumbai"
    }
  }
}
EOF
}

inputs = {
  # Basic Configuration
  cluster_id      = "1"
  cluster_name    = "eks-mumbai"
  cluster_version = "1.33"

  # VPC Dependencies
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  security_group_id  = dependency.vpc.outputs.cluster_security_group_id

  # EKS Node Group Configuration
  node_instance_type    = "t3.small"
  node_desired_capacity = 2
  node_min_size         = 1
  node_max_size         = 4

  # Cross-cluster communication
  peer_vpc_cidr = dependency.peer_vpc.outputs.vpc_cidr_block
}
