################################################################################
# Helm-release: blackbox used to monitor url/ingress
################################################################################
# https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter
# https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter#upgrading-chart
resource "helm_release" "prometheus_blackbox" {
  name       = "prometheus-blackbox-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"
  version    = "8.12.0"
  namespace  = var.namespace

  values = [
    file("${path.module}/values.yaml")
  ]


  # Fix the service name
  set {
    name  = "fullnameOverride"
    value = "prometheus-blackbox-exporter"
  }

  # set {
  #   name  = "serviceMonitor.enabled"
  #   value = true
  # }

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
