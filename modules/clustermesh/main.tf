# ClusterMesh Module - Enables and configures Cilium ClusterMesh across multiple clusters

# Enable ClusterMesh API server for this cluster
resource "null_resource" "enable_clustermesh" {
  count = var.enable_clustermesh ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      # Set kubeconfig context
      export KUBECONFIG=${var.kubeconfig_path}
      kubectl config use-context ${var.cluster_context}
      
      # Enable ClusterMesh (equivalent to: cilium clustermesh enable --context $CLUSTER)
      cilium clustermesh enable --context ${var.cluster_context}
      
      # Wait for ClusterMesh API server to be ready
      kubectl wait --for=condition=ready pod -l k8s-app=clustermesh-apiserver -n kube-system --timeout=300s
    EOT
  }

  triggers = {
    cluster_name    = var.cluster_name
    cluster_context = var.cluster_context
    enable_mesh     = var.enable_clustermesh
  }

  depends_on = [
    var.cilium_ready_dependency
  ]
}

# Create ClusterMesh service for external access (LoadBalancer)
resource "kubernetes_service" "clustermesh_apiserver_external" {
  count = var.enable_clustermesh && var.expose_clustermesh_service ? 1 : 0

  metadata {
    name      = "clustermesh-apiserver-external"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "clustermesh-apiserver"
    }
  }

  spec {
    type = "LoadBalancer"

    port {
      name        = "api"
      port        = 2379
      target_port = 2379
      protocol    = "TCP"
    }

    selector = {
      "k8s-app" = "clustermesh-apiserver"
    }
  }

  depends_on = [null_resource.enable_clustermesh]
}

# Wait for ClusterMesh service to get external IP
resource "null_resource" "wait_for_external_ip" {
  count = var.enable_clustermesh && var.expose_clustermesh_service ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for LoadBalancer to get external IP
      kubectl wait --for=jsonpath='{.status.loadBalancer.ingress}' service/clustermesh-apiserver-external -n kube-system --timeout=300s
    EOT
  }

  depends_on = [kubernetes_service.clustermesh_apiserver_external]
}

# Extract ClusterMesh connection information
data "kubernetes_service" "clustermesh_apiserver_external" {
  count = var.enable_clustermesh && var.expose_clustermesh_service ? 1 : 0

  metadata {
    name      = "clustermesh-apiserver-external"
    namespace = "kube-system"
  }

  depends_on = [null_resource.wait_for_external_ip]
}

# Connect to peer cluster if specified
resource "null_resource" "connect_to_peer" {
  count = var.enable_clustermesh && var.peer_cluster_context != "" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      # Set kubeconfig context
      export KUBECONFIG=${var.kubeconfig_path}
      
      # Connect clusters (equivalent to: cilium clustermesh connect --context $CLUSTER1 --destination-context $CLUSTER2)
      cilium clustermesh connect --context ${var.cluster_context} --destination-context ${var.peer_cluster_context}
      
      # Wait for connection to be established
      sleep 30
      
      # Verify ClusterMesh status
      cilium clustermesh status --context ${var.cluster_context}
    EOT
  }

  triggers = {
    cluster_context      = var.cluster_context
    peer_cluster_context = var.peer_cluster_context
    connection_id        = "${var.cluster_context}-${var.peer_cluster_context}"
  }

  depends_on = [
    null_resource.enable_clustermesh,
    null_resource.wait_for_external_ip
  ]
}

# Create ClusterMesh configuration secret for manual setup if needed
resource "kubernetes_secret" "clustermesh_config" {
  count = var.enable_clustermesh && var.create_manual_config ? 1 : 0

  metadata {
    name      = "clustermesh-config-${var.cluster_name}"
    namespace = "kube-system"
  }

  data = {
    "cluster-name" = var.cluster_name
    "cluster-id"   = tostring(var.cluster_id)
    "service-ip"   = var.expose_clustermesh_service && length(data.kubernetes_service.clustermesh_apiserver_external) > 0 ? data.kubernetes_service.clustermesh_apiserver_external[0].status[0].load_balancer[0].ingress[0].ip : ""
  }

  type = "Opaque"

  depends_on = [null_resource.enable_clustermesh]
}

# Install Cilium CLI if not available
resource "null_resource" "install_cilium_cli" {
  count = var.install_cilium_cli ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      # Check if cilium CLI is installed
      if ! command -v cilium &> /dev/null; then
        echo "Installing Cilium CLI..."
        
        # Detect OS
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        ARCH=$(uname -m)
        
        # Map architecture
        case $ARCH in
          x86_64) ARCH="amd64" ;;
          arm64|aarch64) ARCH="arm64" ;;
          *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
        esac
        
        # Download and install
        CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
        curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/$CILIUM_CLI_VERSION/cilium-$OS-$ARCH.tar.gz
        tar xzvf cilium-$OS-$ARCH.tar.gz
        sudo mv cilium /usr/local/bin
        rm cilium-$OS-$ARCH.tar.gz
        
        echo "Cilium CLI installed successfully"
      else
        echo "Cilium CLI already installed"
      fi
    EOT
  }

  triggers = {
    install_cli = var.install_cilium_cli
  }
}
