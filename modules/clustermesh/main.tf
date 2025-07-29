resource "kubernetes_secret_v1_data" "cilium_clustermesh" {
  metadata {
    name      = "cilium-clustermesh"
    namespace = "kube-system"
  }

  data = {
    "${var.cluster_name}" = jsonencode({
      "endpoints" = [
        var.clustermesh_apiserver_endpoint
      ]
      "trusted-ca-file" = "/var/lib/cilium/clustermesh/${var.cluster_name}-ca.crt"
      "cert-file"       = "/var/lib/cilium/clustermesh/${var.cluster_name}.crt"
      "key-file"        = "/var/lib/cilium/clustermesh/${var.cluster_name}.key"
    })
    "${var.cluster_name}-ca.crt" = base64decode(var.clustermesh_apiserver_remote_cacrt)
    "${var.cluster_name}.crt"    = base64decode(var.clustermesh_apiserver_remote_tlscrt)
    "${var.cluster_name}.key"    = base64decode(var.clustermesh_apiserver_remote_tlskey)
  }
}
