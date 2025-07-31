# Cilium ClusterMesh on EKS

This project sets up a multi-region EKS cluster mesh using Cilium for cross-cluster networking and security.

## Architecture

- **Mumbai Region (ap-south-1)**: EKS cluster with Cilium CNI
- **Singapore Region (ap-southeast-1)**: EKS cluster with Cilium CNI
- **VPC Peering**: Secure connectivity between regions
- **ClusterMesh**: Cilium-based multi-cluster networking

## Prerequisites

- AWS CLI configured with appropriate permissions
- Make

## Development Environment

Initialize the development environment with all required tools:

```bash
make devbox-init    # Install devbox and dependencies
make devbox-shell   # Enter the development environment
```

## Infrastructure Management

### Complete Deployment

Deploy the entire infrastructure with proper sequencing and parallelism:

```bash
# Sequential deployment
make deploy


**Deployment sequence:**
1. **VPCs**: Mumbai and Singapore VPCs deploy in parallel
2. **Peering**: VPC peering connection (sequential, after VPCs)
3. **EKS**: Both EKS clusters deploy in parallel
4. **Cilium**: Cilium CNI installs in parallel on both clusters

### Stage-by-Stage Deployment

Deploy individual stages:

```bash
make deploy-vpcs       # Deploy VPCs in parallel
make deploy-peering    # Deploy VPC peering
make deploy-eks        # Deploy EKS clusters in parallel
make deploy-cilium     # Deploy Cilium in parallel
```

### Component-Level Operations

Execute operations on individual components:

#### Mumbai Region
```bash
# VPC operations
make mumbai/vpc/plan
make mumbai/vpc/apply
make mumbai/vpc/destroy
make mumbai/vpc/output
make mumbai/vpc/validate

# EKS operations
make mumbai/eks/plan
make mumbai/eks/apply
make mumbai/eks/destroy
make mumbai/eks/output
make mumbai/eks/validate

# Cilium operations
make mumbai/cilium/plan
make mumbai/cilium/apply
make mumbai/cilium/destroy
make mumbai/cilium/output
make mumbai/cilium/validate
```

#### Singapore Region
```bash
# VPC operations
make singapore/vpc/plan
make singapore/vpc/apply
make singapore/vpc/destroy
make singapore/vpc/output
make singapore/vpc/validate

# EKS operations
make singapore/eks/plan
make singapore/eks/apply
make singapore/eks/destroy
make singapore/eks/output
make singapore/eks/validate

# Cilium operations
make singapore/cilium/plan
make singapore/cilium/apply
make singapore/cilium/destroy
make singapore/cilium/output
make singapore/cilium/validate
```

#### Cross-Region Components
```bash
# VPC Peering operations
make peering/plan
make peering/apply
make peering/destroy
make peering/output
make peering/validate
```

### Complete Teardown

Destroy all infrastructure in the correct reverse order:

```bash
make destroy
```

**Destruction sequence:**
1. ClusterMesh components
2. Cilium installations
3. EKS clusters
4. VPC peering
5. VPCs

### Development Operations

#### Code Quality
```bash
make validate    # Validate all Terraform configurations
make fmt        # Format Terraform and HCL files
```

#### Cleanup
```bash
make clean      # Remove temporary files and caches
```

## Project Structure

```
├── environments/test/
│   ├── mumbai/              # Mumbai region resources
│   │   ├── vpc/
│   │   ├── eks/
│   │   ├── cilium/
│   │   └── clustermesh/
│   ├── singapore/           # Singapore region resources
│   │   ├── vpc/
│   │   ├── eks/
│   │   ├── cilium/
│   │   └── clustermesh/
│   └── peering/             # Cross-region peering
├── modules/                 # Terraform modules
│   ├── vpc/
│   ├── eks/
│   ├── cilium/
│   ├── clustermesh/
│   └── aws-vpc-peering/
├── kubeconfig/              # Generated kubeconfig files
├── scripts/                 # Utility scripts
├── Makefile                 # Automation targets
├── devbox.json             # Development environment
└── README.md
```

## Tips

1. **Always use the development environment**: `make devbox-shell`
2. **Validate before applying**: Use `plan` targets to preview changes
3. **Check outputs**: Use `output` targets to see resource information
4. **Clean up**: Run `make clean` to remove temporary files

## Troubleshooting

- **Dependency errors**: Ensure prerequisites are deployed first
- **Permission issues**: Verify AWS credentials and permissions
- **State conflicts**: Use `make clean` to remove cached state
- **Network connectivity**: Verify VPC peering and security groups