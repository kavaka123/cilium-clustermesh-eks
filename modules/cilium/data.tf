data "kubernetes_service" "cilium_clustermesh_apiserver" {
  metadata {
    name      = "clustermesh-apiserver"
    namespace = "kube-system"
  }
  depends_on = [helm_release.cilium]
}

data "kubernetes_secret" "cilium_clustermesh_remote_cert" {
  metadata {
    name      = "clustermesh-apiserver-remote-cert"
    namespace = "kube-system"
  }
  binary_data = {
    "ca.crt"  = ""
    "tls.crt" = ""
    "tls.key" = ""
  }
  depends_on = [helm_release.cilium]
}