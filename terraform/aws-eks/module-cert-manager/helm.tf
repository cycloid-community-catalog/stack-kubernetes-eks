# https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager
# changelog: https://github.com/cert-manager/cert-manager/releases
# support version: https://cert-manager.io/docs/releases/#currently-supported-releases
# Plugin for AWS private ACM: https://cert-manager.github.io/aws-privateca-issuer/  https://github.com/cert-manager/aws-privateca-issuer
# ACM Private CA support for cert-manager is now available using the Private CA Kubernetes cert-manager plugin. With the plugin, you can use a highly-available, secure, managed Private CA as an issuer for your Kubernetes cluster. Learn more about the plugin:
#     GitHub - https://github.com/cert-manager/aws-privateca-issuer/
#     AWS tech doc - https://docs.aws.amazon.com/acm-pca/latest/userguide/PcaKubernetes.html

################################################################################
# Helm-release: Cert-Manager
################################################################################
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.16.2"
  namespace  = var.namespace

  # values = [
  #   file("${path.module}/values.yaml")
  # ]

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
    name  = "crds.enabled"
    value = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cert_manager
  ]
}
