################################################################################
# Helm-release: blackbox used to monitor url/ingress
################################################################################
# https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter
# https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter#upgrading-chart
# https://github.com/prometheus/blackbox_exporter/blob/master/CONFIGURATION.md#http_probe
resource "helm_release" "prometheus_blackbox" {
  name       = "prometheus-blackbox-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"
  version    = "11.8.0"
  namespace  = var.namespace

  # values = [
  #   file("${path.module}/values.yaml")
  # ]

  values = [
    local.global_values
  ]


  # Fix the service name
  set = [
    {
      name  = "fullnameOverride"
      value = "prometheus-blackbox-exporter"
    }
  ]
  # {
  #   name  = "serviceMonitor.enabled"
  #   value = true
  # },
  # {
  #   name  = "pspEnabled"
  #   value = false
  # }
}

locals {
  global_values = yamlencode({
    # we override the default config to add insecure_skip_verify=true
    # https://github.com/prometheus/blackbox_exporter/issues/1429#issuecomment-3527378340
    # This overrides should be removed once the issue is fixed
    "config" = {
      "modules" = {
        "http_2xx" = {
          "prober"  = "http"
          "timeout" = "5s"
          "http" = {
            valid_http_versions   = ["HTTP/1.1", "HTTP/2.0"]
            follow_redirects      = true
            preferred_ip_protocol = "ip4"
            tls_config = {
              insecure_skip_verify = true
            }
          }
        }
      }
    }
  })
}

# config:
#   modules:
#     http_2xx:
#       prober: http
#       timeout: 5s
#       http:
#         valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
#         follow_redirects: true
#         preferred_ip_protocol: "ip4"
#     http_2xx_insecure:
#       prober: http
#       timeout: 5s
#       http:
#         valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
#         follow_redirects: true
#         preferred_ip_protocol: "ip4"
#         tls_config:
#           insecure_skip_verify: true
