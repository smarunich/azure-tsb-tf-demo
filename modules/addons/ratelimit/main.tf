provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    token                  = var.k8s_client_token
  }
}

resource "random_password" "redis" {
  length = 16
  # Do not use the ':' character here as it will be read as Basic Auth and tokenized as <user>:<password>
  special = false
}

resource "helm_release" "redis" {
  count            = var.enabled ? 1 : 0
  name             = "redis"
  repository       = "oci://registry-1.docker.io/bitnamicharts/"
  chart            = "redis"
  create_namespace = true
  namespace        = var.namespace
  timeout          = 900

  set {
    name  = "auth.password"
    value = random_password.redis.result
  }
  set {
    name  = "architecture"
    value = "standalone"
  }
}
