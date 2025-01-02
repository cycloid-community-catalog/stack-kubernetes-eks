################################################################################
# K8s extra resources
################################################################################

# Namespace used to deploy infrastructure pods such as nginx controller, aws controller, prometheus ...
resource "kubernetes_namespace_v1" "infra" {
  depends_on = [module.eks-auth]
  metadata {
    name = "infra"
    annotations = {
      "prometheus/monitoring" = "true"
    }
  }
}

variable "k8s_secret_infra_basic_auth_user" {
  default = "admin"
}

resource "random_password" "k8s_secret_infra_basic_auth_password" {
  length  = 32
  special = false
}

# Secret used by ingress from infra namespace to provide Basic auth
resource "kubernetes_secret_v1" "basic-auth-infra" {
  depends_on = [module.eks-auth]
  metadata {
    name      = var.secret_basic_auth_infra_name
    namespace = kubernetes_namespace_v1.infra.metadata.0.name
  }

  data = {
    "${var.k8s_secret_infra_basic_auth_user}" = random_password.k8s_secret_infra_basic_auth_password.bcrypt_hash
  }
}
