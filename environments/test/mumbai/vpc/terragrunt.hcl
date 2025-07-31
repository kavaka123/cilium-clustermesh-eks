# Mumbai VPC Terragrunt Configuration

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/modules/vpc"
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
      Component   = "vpc"
      Cluster     = "mumbai"
    }
  }
}
EOF
}

inputs = {
  # Basic Configuration
  cluster_name = "eks-mumbai"
  region       = "ap-south-1"

  # VPC Configuration
  vpc_cidr             = "10.20.0.0/16"
  public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs = ["10.20.3.0/24", "10.20.4.0/24"]
  availability_zones   = ["ap-south-1a", "ap-south-1b"]

  # VPC Features
  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}
