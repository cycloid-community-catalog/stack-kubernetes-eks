# https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns
################################################################################
# Helm-release: external-dns
################################################################################

resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.18.0"
  namespace  = var.namespace

  # values = [
  #   file("${path.module}/values.yaml")
  # ]

  set = [
    {
      name  = "provider.name"
      value = "aws"
    },
    # Each record created by external-dns is accompanied by the TXT record, which internally stores the external-dns identifier.
    {
      name  = "registry"
      value = "txt"
    },
    # TXT registry identifier.
    {
      name  = "txtOwnerId"
      value = var.cluster_id
    },
    # Verbosity of the logs, available values are: panic, debug, info, warning, error, fatal.
    {
      name  = "logLevel"
      value = "warning"
    },
    # to enable safely deletion of records
    {
      name  = "policy"
      value = "sync"
    },
    {
      name  = "interval"
      value = "1m"
    },
    # pod permissions to access route53
    {
      name  = "serviceAccount.name"
      value = var.service_account_name
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_dns.arn
    },
    {
      name  = "rbac.create"
      value = "true"
    }
  ]
}
