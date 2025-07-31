# Cilium Installation Module for EKS with ENI Datapath

# Install Cilium using Helm
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = var.cilium_version
  namespace  = "kube-system"


  values = [
    yamlencode(merge(
      {
        # Basic configuration
        cluster = {
          name = var.cluster_name
          id   = var.cluster_id
        }

        # ENI datapath configuration
        eni = {
          enabled = true
        }
        ipam = {
          mode = "eni"
        }

        # ipv4NativeRoutingCIDR = "10.0.0.0/8"
        routingMode = "native" # Disable tunneling for ENI mode

        encryption = {
          enabled        = true
          type           = "wireguard"
          nodeEncryption = true
        }

        # Remove node initialization taint
        operator = {
          removeNodeTaints = true
        }

        #Hubble (observability)
        hubble = {
          enabled = var.hubble_enabled
          relay = {
            enabled = var.hubble_enabled
          }
          ui = {
            enabled     = var.hubble_ui_enabled
            rollOutPods = true
          }
        }

        # Resource management
        resources = {
          limits = {
            memory = "500Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
        }
      },
      # Conditionally add TLS CA configuration if paths are provided
      var.ca_cert_path != "" && var.ca_key_path != "" ? {
        tls = {
          ca = {
            cert = base64encode(file(var.ca_cert_path))
            key  = base64encode(file(var.ca_key_path))
          }
        }
      } : {}
    ))
  ]

  # Timeout for installation
  timeout = 600

  # Force update if needed
  force_update = true

  # Wait for deployment
  wait = true
}

# EKS Add-on for CoreDNS (deploy after Cilium is ready)
resource "aws_eks_addon" "coredns" {
  cluster_name = var.cluster_name
  addon_name   = "coredns"

  # Resolve conflicts by overwriting
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Wait for Cilium to be ready and remove node taints
  depends_on = [helm_release.cilium]

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-coredns"
    }
  )
}

# EKS Add-on for metrics-server (deploy after Cilium is ready)
resource "aws_eks_addon" "metrics_server" {
  cluster_name = var.cluster_name
  addon_name   = "metrics-server"

  # Resolve conflicts by overwriting
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Wait for Cilium to be ready and remove node taints
  depends_on = [helm_release.cilium]

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-metrics-server"
    }
  )
}
