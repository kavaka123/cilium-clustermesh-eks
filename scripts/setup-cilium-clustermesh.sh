#!/bin/bash

# Cilium ClusterMesh Setup Script
# This script installs Cilium and sets up ClusterMesh between Mumbai and Singapore clusters

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MUMBAI_CLUSTER_NAME=""
SINGAPORE_CLUSTER_NAME=""
MUMBAI_REGION="ap-south-1"
SINGAPORE_REGION="ap-southeast-1"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if aws cli is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    log_success "All dependencies are available"
}

get_cluster_names() {
    log_info "Getting cluster names from Terraform output..."
    
    if [ -f "terraform.tfstate" ]; then
        MUMBAI_CLUSTER_NAME=$(terraform output -raw mumbai_eks_cluster_id 2>/dev/null || echo "")
        SINGAPORE_CLUSTER_NAME=$(terraform output -raw singapore_eks_cluster_id 2>/dev/null || echo "")
    fi
    
    if [ -z "$MUMBAI_CLUSTER_NAME" ]; then
        read -p "Enter Mumbai cluster name: " MUMBAI_CLUSTER_NAME
    fi
    
    if [ -z "$SINGAPORE_CLUSTER_NAME" ]; then
        read -p "Enter Singapore cluster name: " SINGAPORE_CLUSTER_NAME
    fi
    
    log_info "Mumbai cluster: $MUMBAI_CLUSTER_NAME"
    log_info "Singapore cluster: $SINGAPORE_CLUSTER_NAME"
}

install_cilium_cli() {
    log_info "Installing Cilium CLI..."
    
    if command -v cilium &> /dev/null; then
        log_success "Cilium CLI is already installed"
        return
    fi
    
    # Download and install Cilium CLI
    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
    CLI_ARCH=amd64
    if [[ "$(uname -m)" == "arm64" || "$(uname -m)" == "aarch64" ]]; then
        CLI_ARCH=arm64
    fi
    
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-$(uname -s | tr '[:upper:]' '[:lower:]')-${CLI_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check cilium-$(uname -s | tr '[:upper:]' '[:lower:]')-${CLI_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC cilium-$(uname -s | tr '[:upper:]' '[:lower:]')-${CLI_ARCH}.tar.gz /usr/local/bin
    rm cilium-$(uname -s | tr '[:upper:]' '[:lower:]')-${CLI_ARCH}.tar.gz{,.sha256sum}
    
    log_success "Cilium CLI installed successfully"
}

update_kubeconfig() {
    log_info "Updating kubeconfig for both clusters..."
    
    # Update kubeconfig for Mumbai cluster
    aws eks --region $MUMBAI_REGION update-kubeconfig --name $MUMBAI_CLUSTER_NAME --alias mumbai
    
    # Update kubeconfig for Singapore cluster
    aws eks --region $SINGAPORE_REGION update-kubeconfig --name $SINGAPORE_CLUSTER_NAME --alias singapore
    
    log_success "Kubeconfig updated for both clusters"
}

install_cilium_mumbai() {
    log_info "Installing Cilium on Mumbai cluster..."
    
    kubectl config use-context mumbai
    
    # Wait for nodes to be ready
    log_info "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Install Cilium
    cilium install \
        --cluster-name mumbai \
        --cluster-id 1 \
        --ipam cluster-pool \
        --cluster-pool-ipv4-cidr 10.100.0.0/16 \
        --cluster-pool-ipv4-mask-size 24
    
    # Wait for Cilium to be ready
    log_info "Waiting for Cilium to be ready..."
    cilium status --wait
    
    log_success "Cilium installed successfully on Mumbai cluster"
}

install_cilium_singapore() {
    log_info "Installing Cilium on Singapore cluster..."
    
    kubectl config use-context singapore
    
    # Wait for nodes to be ready
    log_info "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Install Cilium
    cilium install \
        --cluster-name singapore \
        --cluster-id 2 \
        --ipam cluster-pool \
        --cluster-pool-ipv4-cidr 10.200.0.0/16 \
        --cluster-pool-ipv4-mask-size 24
    
    # Wait for Cilium to be ready
    log_info "Waiting for Cilium to be ready..."
    cilium status --wait
    
    log_success "Cilium installed successfully on Singapore cluster"
}

enable_clustermesh_mumbai() {
    log_info "Enabling ClusterMesh on Mumbai cluster..."
    
    kubectl config use-context mumbai
    
    # Enable ClusterMesh
    cilium clustermesh enable --service-type LoadBalancer
    
    # Wait for ClusterMesh to be ready
    log_info "Waiting for ClusterMesh to be ready..."
    cilium clustermesh status --wait
    
    log_success "ClusterMesh enabled on Mumbai cluster"
}

enable_clustermesh_singapore() {
    log_info "Enabling ClusterMesh on Singapore cluster..."
    
    kubectl config use-context singapore
    
    # Enable ClusterMesh
    cilium clustermesh enable --service-type LoadBalancer
    
    # Wait for ClusterMesh to be ready
    log_info "Waiting for ClusterMesh to be ready..."
    cilium clustermesh status --wait
    
    log_success "ClusterMesh enabled on Singapore cluster"
}

connect_clusters() {
    log_info "Connecting clusters..."
    
    kubectl config use-context mumbai
    
    # Connect the clusters
    cilium clustermesh connect --destination-context singapore
    
    # Wait for connectivity
    log_info "Waiting for cluster connectivity..."
    sleep 30
    
    # Check connectivity
    cilium clustermesh status
    
    log_success "Clusters connected successfully"
}

verify_setup() {
    log_info "Verifying ClusterMesh setup..."
    
    # Check Mumbai cluster
    kubectl config use-context mumbai
    log_info "Mumbai cluster status:"
    cilium status
    cilium clustermesh status
    
    # Check Singapore cluster
    kubectl config use-context singapore
    log_info "Singapore cluster status:"
    cilium status
    cilium clustermesh status
    
    log_success "ClusterMesh setup verification completed"
}

# Main execution
main() {
    log_info "Starting Cilium ClusterMesh setup..."
    
    check_dependencies
    get_cluster_names
    install_cilium_cli
    update_kubeconfig
    
    install_cilium_mumbai
    install_cilium_singapore
    
    enable_clustermesh_mumbai
    enable_clustermesh_singapore
    
    connect_clusters
    verify_setup
    
    log_success "Cilium ClusterMesh setup completed successfully!"
    log_info "You can now deploy applications that will be load-balanced across both clusters."
}

# Run main function
main "$@"
