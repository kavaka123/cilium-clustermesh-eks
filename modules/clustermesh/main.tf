resource "kubernetes_secret_v1" "cilium_clustermesh" {
  metadata {
    name      = "cilium-clustermesh"
    namespace = "kube-system"
  }

  data = {
    "${var.cluster_name}" = yamlencode({
      endpoints : ["https://clustermesh-apiserver.kube-system.svc:2379"]
      trusted-ca-file : "/var/lib/cilium/clustermesh/local-etcd-client-ca.crt"
      cert-file : "/var/lib/cilium/clustermesh/local-etcd-client.crt"
      key-file : "/var/lib/cilium/clustermesh/local-etcd-client.key"
    })
  }
}

resource "kubernetes_secret_v1" "cilium_kvstoremesh" {
  metadata {
    name      = "cilium-kvstoremesh"
    namespace = "kube-system"
  }

  data = {
    "${var.cluster_name}" = yamlencode({
      "endpoints" : [var.clustermesh_apiserver_endpoint]
      "trusted-ca-file" : "/var/lib/cilium/clustermesh/${var.cluster_name}.etcd-client-ca.crt"
      "cert-file" : "/var/lib/cilium/clustermesh/${var.cluster_name}.etcd-client.crt"
      "key-file" : "/var/lib/cilium/clustermesh/${var.cluster_name}.etcd-client.key"
    })
    "${var.cluster_name}.etcd-client-ca.crt" = base64decode(var.clustermesh_apiserver_remote_cacrt)
    "${var.cluster_name}.etcd-client.crt"    = base64decode(var.clustermesh_apiserver_remote_tlscrt)
    "${var.cluster_name}.etcd-client.key"    = base64decode(var.clustermesh_apiserver_remote_tlskey)
  }
}
