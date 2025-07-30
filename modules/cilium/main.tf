# Cilium Installation Module for EKS with ENI Datapath

# Install Cilium using Helm
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = var.cilium_version
  namespace  = "kube-system"


  values = [
    yamlencode({
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

      ipv4NativeRoutingCIDR = "10.0.0.0/8"
      # egressMasqueradeInterfaces = "eth0"
      routingMode = "native" # Disable tunneling for ENI mode

      # ClusterMesh configuration
      clustermesh = {
        useAPIServer                       = true
        enableEndpointSliceSynchronization = false
        config = {
          enabled = var.clustermesh_enabled
        }
        apiserver = {
          service = {
            type = "LoadBalancer"
            annotations = merge(
              {
                "service.beta.kubernetes.io/aws-load-balancer-type"                              = "nlb"
                "service.beta.kubernetes.io/aws-load-balancer-scheme"                            = "internal"
                "service.beta.kubernetes.io/aws-load-balancer-internal"                          = "true"
                "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
              },
              length(var.private_subnet_ids) > 0 ? {
                "service.beta.kubernetes.io/aws-load-balancer-subnets" = join(",", var.private_subnet_ids)
              } : {}
            )
          }
        }
      }

      encryption = {
        enabled        = true
        type           = "wireguard"
        nodeEncryption = true
      }

      # Remove node initialization taint
      operator = {
        removeNodeTaints = true
      }

      # Hubble (observability)
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

      # Load balancing
      loadBalancer = {
        algorithm = "maglev"
      }

      # Kubernetes service configuration
      k8sServiceHost = replace(replace(var.cluster_endpoint, "https://", ""), ":443", "")
      k8sServicePort = 443

      # Security
      policyEnforcementMode = var.policy_enforcement_mode

      nodePort = {
        enabled = true
      }

      hostPort = {
        enabled = false
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

      # Node selector for specific node types if needed
      nodeSelector = var.node_selector

      # Tolerations for taints
      tolerations = [
        {
          operator = "Exists"
        }
      ]
    })
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
