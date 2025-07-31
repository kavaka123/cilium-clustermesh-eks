# Cilium ClusterMesh Infrastructure Makefile

# Cluster configuration
CLUSTER1 := mumbai
CLUSTER2 := singapore
KUBECONFIG_DIR := ./kubeconfig
KUBECONFIG := $(KUBECONFIG_DIR)/eks.yaml

terraform_actions := plan apply destroy output validate fmt
terragrunt_units := mumbai/vpc mumbai/eks mumbai/cilium singapore/vpc singapore/eks singapore/cilium peering

terragrunt_cmds = $(foreach unit,$(terragrunt_units), \
	$(foreach action,$(terraform_actions), \
		$(unit)/$(action)))

.PHONY: help deploy deploy-vpcs deploy-peering deploy-eks deploy-cilium generate-ca patch-aws-node mumbai/patch-aws-node singapore/patch-aws-node destroy validate fmt clean devbox-init devbox-shell kubeconfig setup-env mumbai/clustermesh/enable singapore/clustermesh/enable enable-clustermesh clustermesh/connect $(terragrunt_cmds)

# Show help information
help:
	@echo "🚀 Cilium ClusterMesh Infrastructure Management"
	@echo ""
	@echo "📋 Main Commands:"
	@echo "  deploy              Deploy complete infrastructure"
	@echo "  destroy             Destroy all infrastructure"
	@echo "  kubeconfig          Set up kubeconfig for clusters"
	@echo "  setup-env           Create environment setup file"
	@echo ""
	@echo "🏗️  Stage Deployment:"
	@echo "  deploy-vpcs         Deploy VPCs in parallel"
	@echo "  deploy-peering      Deploy VPC peering"
	@echo "  deploy-eks          Deploy EKS clusters in parallel"
	@echo "  generate-ca         Generate shared CA certificates for ClusterMesh"
	@echo "  patch-aws-node      Patch AWS node daemonset on both clusters"
	@echo "  deploy-cilium       Deploy Cilium in parallel"
	@echo ""
	@echo "🌐 ClusterMesh:"
	@echo "  mumbai/clustermesh/enable     Enable ClusterMesh for Mumbai"
	@echo "  singapore/clustermesh/enable  Enable ClusterMesh for Singapore"
	@echo "  enable-clustermesh            Enable ClusterMesh on both clusters"
	@echo "  clustermesh/connect           Connect clusters via ClusterMesh"
	@echo ""
	@echo "🔧 Development:"
	@echo "  devbox-init         Initialize development environment"
	@echo "  devbox-shell        Enter development shell"
	@echo "  validate            Validate all configurations"
	@echo "  fmt                 Format Terraform files"
	@echo "  clean               Clean temporary files"
	@echo ""
	@echo "🌍 Regional Operations:"
	@echo "  mumbai/<component>/<action>     - Mumbai region operations"
	@echo "  singapore/<component>/<action>  - Singapore region operations"
	@echo "  peering/<action>                - Cross-region peering"
	@echo ""
	@echo "📝 Actions: plan, apply, destroy, output, validate, fmt"
	@echo "🏢 Components: vpc, eks, cilium"
	@echo ""
	@echo "💡 Examples:"
	@echo "  make mumbai/vpc/plan"
	@echo "  make singapore/eks/apply"
	@echo "  make deploy -j2"

# Deploy complete infrastructure with proper parallelism
deploy:
	@echo "🚀 Starting infrastructure deployment..."
	@echo "Stage 1: Deploying VPCs in parallel..."
	@$(MAKE) deploy-vpcs -j2
	@echo "Stage 2: Deploying peering..."
	@$(MAKE) deploy-peering
	@echo "Stage 3: Deploying EKS clusters in parallel..."
	@$(MAKE) deploy-eks -j2
	@echo "Stage 4: Generating shared CA certificates..."
	@$(MAKE) generate-ca
	@echo "Stage 5: Patching AWS node daemonset..."
	@$(MAKE) patch-aws-node -j2
	@echo "Stage 6: Deploying Cilium in parallel..."
	@$(MAKE) deploy-cilium -j2
	@echo "Stage 7: Enabling ClusterMesh in parallel..."
	@$(MAKE) enable-clustermesh -j2
	@echo "Stage 8: Connecting clusters via ClusterMesh..."
	@$(MAKE) clustermesh/connect
	@echo "✅ Infrastructure deployment completed!"

# Stage targets
deploy-vpcs: mumbai/vpc/apply singapore/vpc/apply

deploy-peering: peering/apply

deploy-eks: mumbai/eks/apply singapore/eks/apply

# Generate shared CA certificates for ClusterMesh
generate-ca:
	@echo "🔐 Generating shared CA certificates for ClusterMesh..."
	@mkdir -p cacerts
	@if [ ! -f cacerts/ca.key ] || [ ! -f cacerts/ca.crt ]; then \
		echo "Generating new CA certificate..."; \
		openssl genrsa -out cacerts/ca.key 4096; \
		openssl req -new -x509 -key cacerts/ca.key -sha256 \
			-subj "/C=US/ST=CA/O=Cilium/CN=Cilium CA" \
			-days 3650 -out cacerts/ca.crt; \
		echo "✅ CA certificate generated successfully!"; \
	else \
		echo "✅ Using existing CA certificate"; \
	fi

deploy-cilium: mumbai/cilium/apply singapore/cilium/apply

# Patch AWS node daemonset to prevent conflicts with Cilium
patch-aws-node: mumbai/patch-aws-node singapore/patch-aws-node

mumbai/patch-aws-node: kubeconfig
	@echo "🔧 Patching AWS node daemonset for Mumbai cluster..."
	@devbox run -- bash -c "export KUBECONFIG=\"$(PWD)/$(KUBECONFIG)\" && kubectl --context mumbai -n kube-system patch daemonset aws-node --type='strategic' -p='{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"io.cilium/aws-node-enabled\":\"true\"}}}}}'"

singapore/patch-aws-node: kubeconfig
	@echo "🔧 Patching AWS node daemonset for Singapore cluster..."
	@devbox run -- bash -c "export KUBECONFIG=\"$(PWD)/$(KUBECONFIG)\" && kubectl --context singapore -n kube-system patch daemonset aws-node --type='strategic' -p='{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"io.cilium/aws-node-enabled\":\"true\"}}}}}'"


# Destroy complete infrastructure in reverse order
destroy:
	@echo "🔥 Destroying infrastructure..."
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
	@mkdir -p $(KUBECONFIG_DIR)
	@aws eks update-kubeconfig --name eks-mumbai --region ap-south-1 --alias mumbai --kubeconfig $(KUBECONFIG)
	@aws eks update-kubeconfig --name eks-singapore --region ap-southeast-1 --alias singapore --kubeconfig $(KUBECONFIG)
	@echo "✅ Kubeconfig setup completed!"
	@echo "🔧 KUBECONFIG is set to: $(KUBECONFIG)"

# ClusterMesh enable targets - run inside devbox shell
mumbai/clustermesh/enable: kubeconfig
	@echo "🔗 Enabling ClusterMesh for Mumbai cluster..."
	@chmod +x ./scripts/setup-cilium-clustermesh.sh
	@devbox run -- bash -c "export KUBECONFIG=\"$(PWD)/$(KUBECONFIG)\" && ./scripts/setup-cilium-clustermesh.sh $(CLUSTER1)"

singapore/clustermesh/enable: kubeconfig
	@echo "🔗 Enabling ClusterMesh for Singapore cluster..."
	@chmod +x ./scripts/setup-cilium-clustermesh.sh
	@devbox run -- bash -c "export KUBECONFIG=\"$(PWD)/$(KUBECONFIG)\" && ./scripts/setup-cilium-clustermesh.sh $(CLUSTER2)"

# Enable ClusterMesh on both clusters
enable-clustermesh: mumbai/clustermesh/enable singapore/clustermesh/enable
	@echo "✅ ClusterMesh enabled on both clusters!"

# Connect clusters via ClusterMesh
clustermesh/connect: kubeconfig
	@echo "🔗 Connecting clusters via ClusterMesh..."
	@devbox run -- bash -c "export KUBECONFIG=\"$(PWD)/$(KUBECONFIG)\" && cilium clustermesh connect --context $(CLUSTER1) --destination-context $(CLUSTER2)"
	@devbox run -- bash -c "export KUBECONFIG=\"$(PWD)/$(KUBECONFIG)\" && cilium clustermesh status --context $(CLUSTER1) --wait"
	@devbox run -- bash -c "export KUBECONFIG=\"$(PWD)/$(KUBECONFIG)\" && cilium clustermesh status --context $(CLUSTER2) --wait"
	@echo "✅ Clusters connected successfully!"