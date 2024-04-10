# https://github.com/bitnami/charts/tree/main/bitnami/external-dns
# https://github.com/bitnami/charts/tree/main/bitnami/external-dns#upgrading
################################################################################
# Helm-release: external-dns
################################################################################

resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "7.1.2"
  namespace  = var.namespace

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "domainFilters[0]"
    value = var.managed_domain
  }

  # Verbosity of the logs, available values are: panic, debug, info, warning, error, fatal.
  set {
    name  = "logLevel"
    value = "warning"
  }

  # to enable safely deletion of records
  set {
    name  = "policy"
    value = "sync"
  }

  # Each record created by external-dns is accompanied by the TXT record, which internally stores the external-dns identifier.
  set {
    name  = "registry"
    value = "txt"
  }
  # TXT registry identifier.
  set {
    name  = "txtOwnerId"
    value = var.cluster_id
  }

  set {
    name  = "interval"
    value = "1m"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  # pod permissions to access route53
  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns.arn
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

}
