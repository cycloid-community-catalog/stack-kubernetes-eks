################################################################################
# Helm-release: blackbox used to monitor url/ingress
################################################################################
# https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter
# https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter#upgrading-chart
resource "helm_release" "prometheus_blackbox" {
  name       = "prometheus-blackbox-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"
  version    = "9.1.0"
  namespace  = var.namespace

  # values = [
  #   file("${path.module}/values.yaml")
  # ]


  # Fix the service name
  set {
    name  = "fullnameOverride"
    value = "prometheus-blackbox-exporter"
  }

  # set {
  #   name  = "serviceMonitor.enabled"
  #   value = true
  # }

  # set {
  #   name  = "pspEnabled"
  #   value = false
  # }
}
