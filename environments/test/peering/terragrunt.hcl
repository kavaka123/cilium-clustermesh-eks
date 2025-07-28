# VPC Peering Terragrunt Configuration

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws-vpc-peering"
}

# Dependencies - ensure VPCs are created first
dependency "mumbai_vpc" {
  config_path = "../mumbai/vpc"

  mock_outputs = {
    vpc_id                    = "vpc-12345678"
    vpc_cidr_block            = "10.0.0.0/16"
    private_route_table_ids   = ["rtb-12345678"]
    cluster_security_group_id = "sg-12345678"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "singapore_vpc" {
  config_path = "../singapore/vpc"

  mock_outputs = {
    vpc_id                    = "vpc-87654321"
    vpc_cidr_block            = "10.1.0.0/16"
    private_route_table_ids   = ["rtb-87654321"]
    cluster_security_group_id = "sg-87654321"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Generate provider configurations for both regions
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
    }
  }
}

EOF
}

inputs = {
  # Requester (Mumbai) configuration
  requester_vpc_id            = dependency.mumbai_vpc.outputs.vpc_id
  requester_region            = "ap-south-1"
  requester_vpc_cidr          = dependency.mumbai_vpc.outputs.vpc_cidr_block
  requester_route_table_ids   = dependency.mumbai_vpc.outputs.private_route_table_ids
  requester_security_group_id = dependency.mumbai_vpc.outputs.cluster_security_group_id

  # Accepter (Singapore) configuration
  accepter_vpc_id            = dependency.singapore_vpc.outputs.vpc_id
  accepter_region            = "ap-southeast-1"
  accepter_vpc_cidr          = dependency.singapore_vpc.outputs.vpc_cidr_block
  accepter_route_table_ids   = dependency.singapore_vpc.outputs.private_route_table_ids
  accepter_security_group_id = dependency.singapore_vpc.outputs.cluster_security_group_id
}
