# Terragrunt configuration for the root
# This file defines common configuration for all modules

# Generate remote state configuration
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "${get_env("TG_BUCKET_PREFIX", "cilium-clustermesh")}-terraform-state-${get_aws_account_id()}"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

# Common inputs for all modules
inputs = {
  project_name = "cilium-clustermesh"
  environment  = "test"
  owner        = "devops-team"

  # Common tags
  common_tags = {
    Project     = "cilium-clustermesh"
    Environment = "test"
    ManagedBy   = "terragrunt"
    Team        = "platform"
  }
}
