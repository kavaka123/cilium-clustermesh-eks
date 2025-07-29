# Cilium ClusterMesh Infrastructure Makefile

terraform_actions := plan apply destroy output validate fmt
terragrunt_units := mumbai/vpc mumbai/eks mumbai/cilium mumbai/clustermesh singapore/vpc singapore/eks singapore/cilium singapore/clustermesh peering

terragrunt_cmds = $(foreach unit,$(terragrunt_units), \
	$(foreach action,$(terraform_actions), \
		$(unit)/$(action)))

.PHONY: deploy deploy-vpcs deploy-peering deploy-eks deploy-cilium destroy validate fmt clean devbox-init devbox-shell kubeconfig $(terragrunt_cmds)



# Deploy complete infrastructure with proper parallelism
deploy:
	@echo "🚀 Starting infrastructure deployment..."
	@echo "Stage 1: Deploying VPCs in parallel..."
	@$(MAKE) deploy-vpcs -j2
	@echo "Stage 2: Deploying peering..."
	@$(MAKE) deploy-peering
	@echo "Stage 3: Deploying EKS clusters in parallel..."
	@$(MAKE) deploy-eks -j2
	@echo "Stage 4: Deploying Cilium in parallel..."
	@$(MAKE) deploy-cilium -j2
	@echo "✅ Infrastructure deployment completed!"

# Stage targets
deploy-vpcs: mumbai/vpc/apply singapore/vpc/apply

deploy-peering: peering/apply

deploy-eks: mumbai/eks/apply singapore/eks/apply

deploy-cilium: mumbai/cilium/apply singapore/cilium/apply


# Destroy complete infrastructure in reverse order
destroy:
	@echo "🔥 Destroying infrastructure..."
	@echo "Destroying clustermesh components..."
	-$(MAKE) singapore/clustermesh/destroy
	-$(MAKE) mumbai/clustermesh/destroy
	@echo "Destroying cilium components..."
	-$(MAKE) singapore/cilium/destroy
	-$(MAKE) mumbai/cilium/destroy
	@echo "Destroying EKS clusters..."
	-$(MAKE) singapore/eks/destroy
	-$(MAKE) mumbai/eks/destroy
	@echo "Destroying peering..."
	-$(MAKE) peering/destroy
	@echo "Destroying VPCs..."
	-$(MAKE) singapore/vpc/destroy
	-$(MAKE) mumbai/vpc/destroy
	@echo "✅ Infrastructure destroyed!"


$(terragrunt_cmds):
	@echo "Executing $@..."
	@action=$(notdir $@); \
	dir_path=$(dir $@); \
	if [[ "$$action" == "apply" ]]; then \
		cd environments/test/$$dir_path && terragrunt --non-interactive apply -auto-approve ; \
	elif [[ "$$action" == "plan" ]]; then \
		cd environments/test/$$dir_path && terragrunt plan; \
	elif [[ "$$action" == "destroy" ]]; then \
		cd environments/test/$$dir_path && terragrunt --non-interactive destroy  -auto-approve ; \
	elif [[ "$$action" == "output" ]]; then \
		cd environments/test/$$dir_path && terragrunt output; \
	elif [[ "$$action" == "validate" ]]; then \
		cd environments/test/$$dir_path && terragrunt validate; \
	elif [[ "$$action" == "fmt" ]]; then \
		cd environments/test/$$dir_path && terragrunt hclfmt --terragrunt-working-dir .; \
	else \
		echo "Unknown action: $$action"; \
		exit 1; \
	fi
	@echo "✅ $@ completed!"


# Validate all configurations
validate:
	@echo "✅ Validating configurations..."
	@cd environments/test && terragrunt validate -all

# Format Terraform files
fmt:
	@echo "🎨 Formatting Terraform files..."
	@terraform fmt -recursive modules/
	@terragrunt hcl format --working-dir environments/test


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

kubeconfig:
	@echo "🔗 Setting up kubeconfig for EKS clusters..."
	@aws eks update-kubeconfig --name eks-mumbai --region ap-south-1 --alias mumbai --kubeconfig ./kubeconfig/mumbai.yaml
	@aws eks update-kubeconfig --name eks-singapore --region ap-southeast-1 --alias singapore --kubeconfig ./kubeconfig/singapore.yaml
	@echo "✅ Kubeconfig setup completed!"