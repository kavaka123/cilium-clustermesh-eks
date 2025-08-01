# Singapore EKS Terragrunt Configuration

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/eks"
}

# Dependencies - ensure VPC is created first
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                    = "vpc-87654321"
    private_subnet_ids        = ["subnet-87654321", "subnet-12345678"]
    cluster_security_group_id = "sg-87654321"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Generate provider configuration for Singapore region
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
  region = "ap-southeast-1"
  
  default_tags {
    tags = {
      Project     = "cilium-clustermesh"
      Environment = "test"
      Owner       = "devops-team"
      Region      = "ap-southeast-1"
      ManagedBy   = "terragrunt"
      Component   = "eks"
      Cluster     = "singapore"
    }
  }
}
EOF
}

inputs = {
  # Basic Configuration
  cluster_id      = "2"
  cluster_name    = "eks-singapore"
  cluster_version = "1.31"

  # VPC Dependencies
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  security_group_id  = dependency.vpc.outputs.cluster_security_group_id

  # EKS Node Group Configuration
  node_instance_type    = "t3.small"
  node_desired_capacity = 2
  node_min_size         = 1
  node_max_size         = 4

  service_cidr = "172.21.0.0/16"
}
