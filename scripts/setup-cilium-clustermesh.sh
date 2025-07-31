#!/bin/bash

# Cilium ClusterMesh Enable Script
# This script enables ClusterMesh for a specific cluster context

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if context argument is provided
if [ $# -ne 1 ]; then
    log_error "Usage: $0 <context>"
    log_error "Example: $0 mumbai"
    log_error "Example: $0 singapore"
    exit 1
fi

CONTEXT=$1

# Validate context
if [[ "$CONTEXT" != "mumbai" && "$CONTEXT" != "singapore" ]]; then
    log_error "Invalid context: $CONTEXT"
    log_error "Valid contexts are: mumbai, singapore"
    exit 1
fi

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not available in PATH"
        exit 1
    fi
    
    # Check if cilium CLI is installed
    if ! command -v cilium &> /dev/null; then
        log_error "cilium CLI is not installed or not available in PATH"
        log_error "Make sure you're running this script inside devbox shell"
        exit 1
    fi
    
    log_success "All dependencies are available"
}

# Enable ClusterMesh for the specified context
enable_clustermesh() {
    log_info "Enabling ClusterMesh for context: $CONTEXT"
    
    # Check if context exists
    if ! kubectl config get-contexts "$CONTEXT" &> /dev/null; then
        log_error "Context '$CONTEXT' not found in kubeconfig"
        log_error "Run 'make kubeconfig' to set up cluster contexts"
        exit 1
    fi
    
    # Enable ClusterMesh
    log_info "Running: cilium clustermesh enable --context $CONTEXT"
    cilium clustermesh enable --context "$CONTEXT"
    
    # Wait for ClusterMesh to be ready and show status
    log_info "Waiting for ClusterMesh to be ready..."
    log_info "Running: cilium clustermesh status --context $CONTEXT --wait"
    cilium clustermesh status --context "$CONTEXT" --wait
    
    log_success "ClusterMesh enabled successfully for context: $CONTEXT"
}

# Main execution
main() {
    log_info "Starting Cilium ClusterMesh enable for context: $CONTEXT"
    
    check_dependencies
    enable_clustermesh
    
    log_success "ClusterMesh setup completed successfully for context: $CONTEXT"
}

# Run main function
main
