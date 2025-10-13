################################################################################
# Helm-release: prometheus
################################################################################

# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack/templates/prometheus/rules-1.14
locals {
  service_enabled = [
    "grafana",
    "prometheus",
    "alertmanager"
  ]

  rules_disabled = [
    "etcd",
    "configReloaders",
    "kubeApiserverBurnrate",
    "kubeApiserverHistogram",
    "kubeApiserverSlos",
    "kubeControllerManager",
    "kubeSchedulerAlerting",
    "kubeSchedulerRecording",
    "alertmanager",
    "prometheus",
    "network",
    "kubernetesStorage",
    "kubernetesApps",
    "windows"
  ]

  #  (from kubernetesApps rules): because we override labels/for
  alerts_disabled = [
    "KubeQuotaAlmostFull",
    "KubeQuotaFullyUsed",
    "KubeQuotaExceeded",
    "CPUThrottlingHigh",
    "KubeClientCertificateExpiration",
    "KubeAggregatedAPIErrors",
    "KubeAggregatedAPIDown",
    "KubeAPITerminatedRequests",
    "KubeNodeReadinessFlapping",
    "KubeletPlegDurationHigh",
    "KubeletPodStartUpLatencyHigh",
    "KubeletClientCertificateExpiration",
    "KubeletServerCertificateExpiration",
    "KubeletClientCertificateRenewalErrors",
    "KubeletServerCertificateRenewalErrors",
    "KubeletTooManyPods",
    "KubeletDown",
    "NodeNetworkReceiveErrs",
    "NodeNetworkTransmitErrs",
    "NodeHighNumberConntrackEntriesUsed",
    "NodeTextFileCollectorScrapeError",
    "NodeClockSkewDetected",
    "NodeClockNotSynchronising",
    "NodeRAIDDegraded",
    "NodeRAIDDiskFailure",
    "NodeMemoryHighUtilization",
    "NodeSystemSaturation",
    "PrometheusTSDBReloadsFailing",
    "PrometheusTSDBCompactionsFailing",
    "PrometheusNotIngestingSamples",
    "PrometheusDuplicateTimestamps",
    "PrometheusOutOfOrderTimestamps",
    "PrometheusRemoteStorageFailures",
    "PrometheusRemoteWriteBehind",
    "PrometheusRemoteWriteDesiredShards",
    "PrometheusRuleFailures",
    "PrometheusMissingRuleEvaluations",
    "PrometheusLabelLimitHit",
    "PrometheusScrapeBodySizeLimitHit",
    "PrometheusScrapeSampleLimitHit",
    "PrometheusTargetSyncFailure",
    "PrometheusHighQueryLoad",
    "InfoInhibitor",
    "Watchdog"
  ]

  # otheride default rules to change the for and severity
  # Add: * on (namespace) group_left() kube_namespace_annotations{annotation_prometheus_monitoring="true"}
  # So it only check pod in namespace with prometheus/monitoring=true annotation

  # kubectl -n infra get configmap prometheus-kube-prometheus-stack-prometheus-rulefiles-0 -o yaml
  prom_additional_rules = file("${path.module}/prom_additional_rules.yaml")

  prom_additional_scrape_configs = <<EOL
---
prometheus:
  prometheusSpec:
    additionalScrapeConfigs:
      - job_name: kubernetes-ingresses
        metrics_path: /probe
        params:
          module: [http_2xx]
        kubernetes_sd_configs:
        - role: ingress
        relabel_configs:
          # available labels: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#ingress
          # only keep ingress with prometheus/monitoring = true label
          - source_labels: [__meta_kubernetes_ingress_annotation_prometheus_monitoring]
            action: keep
            regex: true

          # check the ingress schema/url/path (default all)
          - source_labels: [__meta_kubernetes_ingress_scheme,__address__,__meta_kubernetes_ingress_path]
            regex: (.+);(.+);(.+)
            replacement: $${1}://$${2}$${3}
            target_label: __param_target

          # 2. Save address in an instance label since __param_target is going to be dropped
          - source_labels: [__param_target]
            target_label: instance

          # 3. Replace address with an internal blackbox service so scraper is always pointed at blackbox-exporter
          - target_label: __address__
            replacement: prometheus-blackbox-exporter:9115

          - action: labelmap
            regex: __meta_kubernetes_ingress_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            target_label: namespace
          - source_labels: [__meta_kubernetes_ingress_name]
            target_label: kubernetes_name

EOL

  #   prom_additional_alertmanager_config = <<EOL
  # ---
  # prometheus:
  #   prometheusSpec:
  #     additionalAlertManagerConfigs:
  #       - scheme: https
  #         basic_auth:
  #           username: ${var.oncall_alertnamager_cred.username}
  #           password: ${var.oncall_alertnamager_cred.password}
  #         static_configs:
  #         - targets:
  #           - 'alertmanager-0.infra.cycloid.io'
  #           - 'alertmanager-1.infra.cycloid.io'
  # EOL

  # prom_additional_alertmanager_config = var.oncall_enabled ? local.prom_additional_alertmanager_config_default : ""

  # compose the main values map used by helm_release
  global_values = yamlencode({
    ########################
    # kube-state-metrics   #
    ########################
    # In order to get annotations on kube_namespace_annotations metrics, we need to allow it on kube-state-metrics
    # https://github.com/kubernetes/kube-state-metrics/issues/1582
    kubeStateMetrics = {
      enabled                    = true
      metricAnnotationsAllowList = ["namespaces=[*]"]
    }

    ########################
    # Grafana              #
    ########################
    grafana = {
      enabled                   = contains(local.service_enabled, "grafana")
      defaultDashboardsTimezone = "Europe/Paris"
      # Set a basic auth on prometheus ingress
      ingress = {
        enabled = contains(local.service_enabled, "grafana")
        hosts = [
          "grafana.${var.project}-${var.env}.phrasea.io"
        ]
        annotations = {
          "nginx.ingress.kubernetes.io/auth-type"          = "basic"
          "nginx.ingress.kubernetes.io/auth-secret"        = var.secret_basic_auth_infra_name
          "nginx.ingress.kubernetes.io/auth-secret-type"   = "auth-map"
          "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
        }
      }
    }

    ########################
    # Prometheus           #
    ########################
    prometheus = {
      enabled = contains(local.service_enabled, "prometheus")
      ingress = {
        enabled = contains(local.service_enabled, "prometheus")
        hosts = [
          "prometheus.${var.project}-${var.env}.phrasea.io"
        ]
        annotations = {
          "nginx.ingress.kubernetes.io/auth-type"          = "basic"
          "nginx.ingress.kubernetes.io/auth-secret"        = var.secret_basic_auth_infra_name
          "nginx.ingress.kubernetes.io/auth-secret-type"   = "auth-map"
          "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
        }
      }

      prometheusSpec = {
        storageSpec = {
          volumeClaimTemplate = {
            # Prometheus server data Persistent Volume config
            # change default pv name because because pvc can't be changed
            metadata = { name = "prometheus" }
            spec = {
              resources        = { requests = { storage = "1Gi" } }
              storageClassName = kubernetes_storage_class_v1.efs.id
              accessModes      = ["ReadWriteOnce"]
            }
          }
        }
        retention = "40d"
        externalLabels = {
          customer = "alchemy"
          env      = var.env
          project  = var.project
          receiver = "on_call"
        }

        nodeSelector = {
          infra = "true"
        }
      }
    }

    ########################
    # Alertmanager         #
    ########################
    alertmanager = {
      enabled = contains(local.service_enabled, "alertmanager")
      ingress = {
        enabled = contains(local.service_enabled, "alertmanager")
        hosts = [
          "alertmanager.${var.project}-${var.env}.phrasea.io"
        ]
        annotations = {
          "nginx.ingress.kubernetes.io/auth-type"          = "basic"
          "nginx.ingress.kubernetes.io/auth-secret"        = var.secret_basic_auth_infra_name
          "nginx.ingress.kubernetes.io/auth-secret-type"   = "auth-map"
          "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
        }
      }
    }

    # disable specific default rules globally
    defaultRules = {
      # Disable monitoring rule
      # https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack/templates/prometheus/rules-1.14
      rules = { for r in local.rules_disabled : r => false }
      # Disable specific Alert from rules
      # Usefull if alert not used or overrided
      disabled = { for a in local.alerts_disabled : a => true }
    }

    # disable specific scrapers
    # chart expects service names lowerCamelCase for many components: adapt as needed
    kubeControllerManager = { enabled = false }
    kubeScheduler         = { enabled = false }
    kubeDns               = { enabled = false }
    kubeEtcd              = { enabled = false }
    kubeProxy             = { enabled = false }

    # other labels
    commonLabels = {
      project   = var.project
      env       = var.env
      component = "eks"
    }

    # Add any extra raw YAML blobs you had
    additionalPrometheusRules = local.prom_additional_rules != "" ? local.prom_additional_rules : null

    # example secret mounts or other chart values you used previously
    # secretMounts example if the chart supports it:
    secretMounts = [
      {
        name       = "elastic-certs"
        secretName = "cost-explorer-es-cert"
        path       = "/ssl"
      }
    ]

    # any other overrides you had as a set can be mapped here similarly...
    }
  )
}

# prom_additional_alertmanager_config = var.oncall_enabled ? local.prom_additional_alertmanager_config_default : ""

#oncall_alertnamager_cred.username
#oncall_alertnamager_cred.password

# https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack
# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#upgrading-an-existing-release-to-a-new-major-version
resource "helm_release" "prometheus_community" {
  count      = var.prometheus_enabled ? 1 : 0
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "67.8.0"
  namespace  = var.namespace

  # file("${path.module}/values.yaml"),
  values = [
    local.global_values,
    local.prom_additional_rules,
    local.prom_additional_scrape_configs,
  ]
  # var.oncall_enabled ? local.prom_additional_alertmanager_config : ""


  ########################
  # Global/Services      #
  ########################
  # service_disabled


  # Can't be set here due to issue with
  # │ Error: template: kube-prometheus-stack/charts/grafana/templates/ingress.yaml:23:23: executing "kube-prometheus-stack/charts/grafana/templates/ingress.yaml" at <$value>: wrong type for value; expected string; got bool
  # dynamic "set" {
  #   for_each = toset(local.service_enabled)
  #   content {
  #     name  = "${set.key}.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/force-ssl-redirect"
  #     value = "true"
  #   }
  # }

  # set {
  #   name  = "prometheus.prometheusSpec.logLevel"
  #   value = "error"
  # }


  ########################
  # Grafana              #
  ########################

  set_sensitive = [
    {
      name  = "grafana.adminPassword"
      value = random_password.password.result
    }
  ]
}
