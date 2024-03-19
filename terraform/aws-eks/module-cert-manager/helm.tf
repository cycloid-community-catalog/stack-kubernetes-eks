# https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager
# https://github.com/cert-manager/cert-manager/releases
################################################################################
# Helm-release: Cert-Manager
################################################################################
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.14.4"
  namespace  = var.namespace

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cert_manager.arn
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }
  set {
    name  = "securityContext.fsGroup"
    value = 1001
  }
  set {
    name  = "installCRDs"
    value = true
  }
  set {
    name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight"
    value = "100"
  }

  set {
    name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key"
    value = "node.type"
  }

  set {
    name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].operator"
    value = "In"
  }

  set {
    name  = "affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].values[0]"
    value = "infra"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cert_manager
  ]
}
