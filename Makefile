# Cilium ClusterMesh Infrastructure Makefile

.PHONY: help deploy destroy status plan validate fmt clean kubeconfig
.PHONY: mumbai-vpc mumbai-eks singapore-vpc singapore-eks peering devbox-init devbox-shell
.PHONY: mumbai/vpc/plan mumbai/vpc/apply mumbai/vpc/destroy
.PHONY: mumbai/eks/plan mumbai/eks/apply mumbai/eks/destroy
.PHONY: mumbai/cilium/plan mumbai/cilium/apply mumbai/cilium/destroy
.PHONY: mumbai/clustermesh/plan mumbai/clustermesh/apply mumbai/clustermesh/destroy
.PHONY: singapore/vpc/plan singapore/vpc/apply singapore/vpc/destroy
.PHONY: singapore/eks/plan singapore/eks/apply singapore/eks/destroy
.PHONY: singapore/cilium/plan singapore/cilium/apply singapore/cilium/destroy
.PHONY: singapore/clustermesh/plan singapore/clustermesh/apply singapore/clustermesh/destroy
.PHONY: peering/plan peering/apply peering/destroy

# Default target
help:
	@echo "Cilium ClusterMesh Infrastructure"
	@echo ""
	@echo "Usage:"
	@echo "  make devbox-init - Initialize devbox environment"
	@echo "  make devbox-shell- Enter devbox shell with all tools"
	@echo ""
	@echo "Infrastructure:"
	@echo "  make deploy     - Deploy complete infrastructure"
	@echo "  make destroy    - Destroy complete infrastructure" 
	@echo "  make status     - Show deployment status"
	@echo "  make plan       - Plan all changes"
	@echo "  make validate   - Validate configurations"
	@echo "  make fmt        - Format Terraform files"
	@echo "  make clean      - Clean temporary files"
	@echo "  make kubeconfig - Update kubectl configuration"
	@echo ""
	@echo "Individual components:"
	@echo "  make mumbai-vpc     - Deploy Mumbai VPC"
	@echo "  make mumbai-eks     - Deploy Mumbai EKS"
	@echo "  make singapore-vpc  - Deploy Singapore VPC"
	@echo "  make singapore-eks  - Deploy Singapore EKS"
	@echo "  make peering        - Deploy VPC peering"
	@echo ""
	@echo "Planning components:"
	@echo "  make mumbai/vpc/plan      - Plan Mumbai VPC changes"
	@echo "  make mumbai/eks/plan      - Plan Mumbai EKS changes"
	@echo "  make mumbai/cilium/plan   - Plan Mumbai Cilium changes"
	@echo "  make mumbai/clustermesh/plan - Plan Mumbai ClusterMesh changes"
	@echo "  make singapore/vpc/plan   - Plan Singapore VPC changes"
	@echo "  make singapore/eks/plan   - Plan Singapore EKS changes"
	@echo "  make singapore/cilium/plan - Plan Singapore Cilium changes"
	@echo "  make singapore/clustermesh/plan - Plan Singapore ClusterMesh changes"
	@echo "  make peering/plan         - Plan VPC peering changes"
	@echo ""
	@echo "Applying components:"
	@echo "  make mumbai/vpc/apply     - Apply Mumbai VPC changes"
	@echo "  make mumbai/eks/apply     - Apply Mumbai EKS changes"
	@echo "  make mumbai/cilium/apply  - Apply Mumbai Cilium changes"
	@echo "  make mumbai/clustermesh/apply - Apply Mumbai ClusterMesh changes"
	@echo "  make singapore/vpc/apply  - Apply Singapore VPC changes"
	@echo "  make singapore/eks/apply  - Apply Singapore EKS changes"
	@echo "  make singapore/cilium/apply - Apply Singapore Cilium changes"
	@echo "  make singapore/clustermesh/apply - Apply Singapore ClusterMesh changes"
	@echo "  make peering/apply        - Apply VPC peering changes"
	@echo ""
	@echo "Destroying components:"
	@echo "  make mumbai/vpc/destroy   - Destroy Mumbai VPC"
	@echo "  make mumbai/eks/destroy   - Destroy Mumbai EKS"
	@echo "  make mumbai/cilium/destroy - Destroy Mumbai Cilium"
	@echo "  make mumbai/clustermesh/destroy - Destroy Mumbai ClusterMesh"
	@echo "  make singapore/vpc/destroy - Destroy Singapore VPC"
	@echo "  make singapore/eks/destroy - Destroy Singapore EKS"
	@echo "  make singapore/cilium/destroy - Destroy Singapore Cilium"
	@echo "  make singapore/clustermesh/destroy - Destroy Singapore ClusterMesh"
	@echo "  make peering/destroy      - Destroy VPC peering"

# Deploy complete infrastructure in order
deploy: mumbai-vpc singapore-vpc mumbai-eks singapore-eks peering
	@echo "✅ Infrastructure deployment completed!"
	@echo "Next step: Run 'make kubeconfig' to configure kubectl"

# Destroy complete infrastructure in reverse order
destroy:
	@echo "🔥 Destroying infrastructure..."
	@cd environments/test/peering && terragrunt destroy --auto-approve
	@cd environments/test/singapore/eks && terragrunt destroy --auto-approve
	@cd environments/test/mumbai/eks && terragrunt destroy --auto-approve
	@cd environments/test/singapore/vpc && terragrunt destroy --auto-approve
	@cd environments/test/mumbai/vpc && terragrunt destroy --auto-approve
	@echo "✅ Infrastructure destroyed!"

# Show status of deployments
status:
	@echo "📊 Infrastructure Status:"
	@echo ""
	@echo "Mumbai VPC:"
	@cd environments/test/mumbai/vpc && terragrunt show 2>/dev/null | head -5 || echo "  Not deployed"
	@echo ""
	@echo "Mumbai EKS:"
	@cd environments/test/mumbai/eks && terragrunt show 2>/dev/null | head -5 || echo "  Not deployed"
	@echo ""
	@echo "Singapore VPC:"
	@cd environments/test/singapore/vpc && terragrunt show 2>/dev/null | head -5 || echo "  Not deployed"
	@echo ""
	@echo "Singapore EKS:"
	@cd environments/test/singapore/eks && terragrunt show 2>/dev/null | head -5 || echo "  Not deployed"
	@echo ""
	@echo "Peering:"
	@cd environments/test/peering && terragrunt show 2>/dev/null | head -5 || echo "  Not deployed"

# Plan all changes
plan:
	@echo "📋 Planning infrastructure changes..."
	@cd environments/test && terragrunt run-all plan

# Deploy Mumbai VPC
mumbai-vpc:
	@echo "🇮🇳 Deploying Mumbai VPC..."
	@cd environments/test/mumbai/vpc && terragrunt apply --auto-approve

# Deploy Mumbai EKS
mumbai-eks:
	@echo "🇮🇳 Deploying Mumbai EKS cluster..."
	@cd environments/test/mumbai/eks && terragrunt apply --auto-approve

# Deploy Singapore VPC
singapore-vpc:
	@echo "🇸🇬 Deploying Singapore VPC..."
	@cd environments/test/singapore/vpc && terragrunt apply --auto-approve

# Deploy Singapore EKS
singapore-eks:
	@echo "🇸🇬 Deploying Singapore EKS cluster..."
	@cd environments/test/singapore/eks && terragrunt apply --auto-approve

# Deploy VPC peering
peering:
	@echo "🔗 Deploying VPC peering..."
	@cd environments/test/peering && terragrunt apply --auto-approve

# Plan targets for each component
mumbai/vpc/plan:
	@echo "📋 Planning Mumbai VPC changes..."
	@cd environments/test/mumbai/vpc && terragrunt plan

mumbai/eks/plan:
	@echo "📋 Planning Mumbai EKS changes..."
	@cd environments/test/mumbai/eks && terragrunt plan

mumbai/cilium/plan:
	@echo "📋 Planning Mumbai Cilium changes..."
	@cd environments/test/mumbai/cilium && terragrunt plan

mumbai/clustermesh/plan:
	@echo "📋 Planning Mumbai ClusterMesh changes..."
	@cd environments/test/mumbai/clustermesh && terragrunt plan

singapore/vpc/plan:
	@echo "📋 Planning Singapore VPC changes..."
	@cd environments/test/singapore/vpc && terragrunt plan

singapore/eks/plan:
	@echo "📋 Planning Singapore EKS changes..."
	@cd environments/test/singapore/eks && terragrunt plan

singapore/cilium/plan:
	@echo "📋 Planning Singapore Cilium changes..."
	@cd environments/test/singapore/cilium && terragrunt plan

singapore/clustermesh/plan:
	@echo "📋 Planning Singapore ClusterMesh changes..."
	@cd environments/test/singapore/clustermesh && terragrunt plan

peering/plan:
	@echo "📋 Planning VPC peering changes..."
	@cd environments/test/peering && terragrunt plan

# Apply targets for each component
mumbai/vpc/apply:
	@echo "🇮🇳 Applying Mumbai VPC changes..."
	@cd environments/test/mumbai/vpc && terragrunt apply --auto-approve

mumbai/eks/apply:
	@echo "🇮🇳 Applying Mumbai EKS changes..."
	@cd environments/test/mumbai/eks && terragrunt apply --auto-approve

mumbai/cilium/apply:
	@echo "🇮🇳 Applying Mumbai Cilium changes..."
	@cd environments/test/mumbai/cilium && terragrunt apply --auto-approve

mumbai/clustermesh/apply:
	@echo "🇮🇳 Applying Mumbai ClusterMesh changes..."
	@cd environments/test/mumbai/clustermesh && terragrunt apply --auto-approve

singapore/vpc/apply:
	@echo "🇸🇬 Applying Singapore VPC changes..."
	@cd environments/test/singapore/vpc && terragrunt apply --auto-approve

singapore/eks/apply:
	@echo "🇸🇬 Applying Singapore EKS changes..."
	@cd environments/test/singapore/eks && terragrunt apply --auto-approve

singapore/cilium/apply:
	@echo "🇸🇬 Applying Singapore Cilium changes..."
	@cd environments/test/singapore/cilium && terragrunt apply --auto-approve

singapore/clustermesh/apply:
	@echo "🇸🇬 Applying Singapore ClusterMesh changes..."
	@cd environments/test/singapore/clustermesh && terragrunt apply --auto-approve

peering/apply:
	@echo "🔗 Applying VPC peering changes..."
	@cd environments/test/peering && terragrunt apply --auto-approve

# Destroy targets for each component
mumbai/vpc/destroy:
	@echo "🔥 Destroying Mumbai VPC..."
	@cd environments/test/mumbai/vpc && terragrunt destroy --auto-approve

mumbai/eks/destroy:
	@echo "🔥 Destroying Mumbai EKS cluster..."
	@cd environments/test/mumbai/eks && terragrunt destroy --auto-approve

mumbai/cilium/destroy:
	@echo "🔥 Destroying Mumbai Cilium..."
	@cd environments/test/mumbai/cilium && terragrunt destroy --auto-approve

mumbai/clustermesh/destroy:
	@echo "🔥 Destroying Mumbai ClusterMesh..."
	@cd environments/test/mumbai/clustermesh && terragrunt destroy --auto-approve

singapore/vpc/destroy:
	@echo "🔥 Destroying Singapore VPC..."
	@cd environments/test/singapore/vpc && terragrunt destroy --auto-approve

singapore/eks/destroy:
	@echo "🔥 Destroying Singapore EKS cluster..."
	@cd environments/test/singapore/eks && terragrunt destroy --auto-approve

singapore/cilium/destroy:
	@echo "🔥 Destroying Singapore Cilium..."
	@cd environments/test/singapore/cilium && terragrunt destroy --auto-approve

singapore/clustermesh/destroy:
	@echo "🔥 Destroying Singapore ClusterMesh..."
	@cd environments/test/singapore/clustermesh && terragrunt destroy --auto-approve

peering/destroy:
	@echo "🔥 Destroying VPC peering..."
	@cd environments/test/peering && terragrunt destroy --auto-approve

# Validate all configurations
validate:
	@echo "✅ Validating configurations..."
	@cd environments/test && terragrunt run-all validate

# Format Terraform files
fmt:
	@echo "🎨 Formatting Terraform files..."
	@terraform fmt -recursive modules/
	@terragrunt hclfmt --terragrunt-working-dir environments/test

# Update kubeconfig for both clusters
kubeconfig:
	@echo "⚙️ Updating kubeconfig..."
	@aws eks --region ap-south-1 update-kubeconfig --name cilium-clustermesh-test-mumbai --alias mumbai
	@aws eks --region ap-southeast-1 update-kubeconfig --name cilium-clustermesh-test-singapore --alias singapore
	@echo "✅ Kubeconfig updated!"
	@echo "Test with: kubectl --context=mumbai get nodes"

# Clean temporary files
clean:
	@echo "🧹 Cleaning temporary files..."
	@find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.tfplan" -delete 2>/dev/null || true
	@find . -name "terraform.log" -delete 2>/dev/null || true
	@echo "✅ Cleanup completed!"

# Initialize devbox environment
devbox-init:
	@echo "🚀 Initializing devbox environment..."
	@if ! command -v devbox >/dev/null 2>&1; then \
		echo "Installing devbox..."; \
		curl -fsSL https://get.jetpack.io/devbox | bash; \
	fi
	@devbox install
	@echo "✅ Devbox environment ready!"
	@echo "Run 'make devbox-shell' or 'devbox shell' to enter the environment"

# Enter devbox shell
devbox-shell:
	@echo "🐚 Entering devbox shell..."
	@devbox shell
