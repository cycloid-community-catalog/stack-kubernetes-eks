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

  # "alertmanager",
  service_disabled = [
    "kubeControllerManager",
    "KubeScheduler"
  ]

  scrapping_disabled = ["kubeDns", "kubeEtcd", "kubeProxy"]

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

          # check the ingress schema/url/path
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
            target_label: kubernetes_namespace
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

}
#oncall_alertnamager_cred.username
#oncall_alertnamager_cred.password

# https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack
resource "helm_release" "prometheus_community" {
  count      = var.prometheus_enabled ? 1 : 0
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "56.14.0"
  namespace  = var.namespace

  values = [
    file("${path.module}/values.yaml"),
    local.prom_additional_rules,
    local.prom_additional_scrape_configs,
  ]
  # var.oncall_enabled ? local.prom_additional_alertmanager_config : ""


  ########################
  # Global/Services      #
  ########################
  # service_disabled
  dynamic "set" {
    for_each = toset(local.service_disabled)
    content {
      name  = "${set.key}.enabled"
      value = false
    }
  }

  # enable
  dynamic "set" {
    for_each = toset(local.service_enabled)
    content {
      name  = "${set.key}.enabled"
      value = true
    }
  }

  # ingress
  dynamic "set" {
    for_each = toset(local.service_enabled)
    content {
      name  = "${set.key}.ingress.enabled"
      value = true
    }
  }
  dynamic "set" {
    for_each = toset(local.service_enabled)
    content {
      name  = "${set.key}.ingress.hosts[0]"
      value = "${set.key}.${var.project}-${var.env}.phrasea.io"
    }
  }

  # Set a basic auth on prometheus ingress
  dynamic "set" {
    for_each = toset(local.service_enabled)
    content {
      name  = "${set.key}.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-type"
      value = "basic"
    }
  }
  dynamic "set" {
    for_each = toset(local.service_enabled)
    content {
      name  = "${set.key}.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-secret"
      value = var.secret_basic_auth_infra_name
    }
  }
  dynamic "set" {
    for_each = toset(local.service_enabled)
    content {
      name  = "${set.key}.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-secret-type"
      value = "auth-map"
    }
  }

  # Can't be set here due to issue with
  # │ Error: template: kube-prometheus-stack/charts/grafana/templates/ingress.yaml:23:23: executing "kube-prometheus-stack/charts/grafana/templates/ingress.yaml" at <$value>: wrong type for value; expected string; got bool
  # dynamic "set" {
  #   for_each = toset(local.service_enabled)
  #   content {
  #     name  = "${set.key}.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/force-ssl-redirect"
  #     value = "true"
  #   }
  # }

  # Disable monitoring rule
  # https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack/templates/prometheus/rules-1.14
  dynamic "set" {
    for_each = toset(local.rules_disabled)
    content {
      name  = "defaultRules.rules.${set.key}"
      value = false
    }
  }

  # Disable specific Alert from rules
  # Usefull if alert not used or overrided
  dynamic "set" {
    for_each = toset(local.alerts_disabled)
    content {
      name  = "defaultRules.disabled.${set.key}"
      value = true
    }
  }

  dynamic "set" {
    for_each = toset(local.scrapping_disabled)
    content {
      name  = "${set.key}.enabled"
      value = false
    }
  }


  ########################
  # Prometheus           #
  ########################

  # Prometheus server data Persistent Volume config
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "${var.prometheus_pvc_size}Gi"
  }
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class_name
  }
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
  }

  # Prometheus data retention period
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "40d"
  }

  set {
    name  = "prometheus.prometheusSpec.externalLabels.customer"
    value = var.organization
  }
  set {
    name  = "prometheus.prometheusSpec.externalLabels.env"
    value = var.env
  }
  set {
    name  = "prometheus.prometheusSpec.externalLabels.project"
    value = var.project
  }
  set {
    name  = "prometheus.prometheusSpec.externalLabels.receiver"
    value = "on_call"
  }

  # set {
  #   name  = "prometheus.prometheusSpec.logLevel"
  #   value = "error"
  # }

  set {
    name  = "prometheus.prometheusSpec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight"
    value = "100"
  }

  set {
    name  = "prometheus.prometheusSpec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key"
    value = "node.type"
  }

  set {
    name  = "prometheus.prometheusSpec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].operator"
    value = "In"
  }

  set {
    name  = "prometheus.prometheusSpec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].values[0]"
    value = "infra"
  }


  set {
    name  = "prometheus.prometheusOperator.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight"
    value = "100"
  }

  set {
    name  = "prometheus.prometheusOperator.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key"
    value = "node.type"
  }

  set {
    name  = "prometheus.prometheusOperator.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].operator"
    value = "In"
  }

  set {
    name  = "prometheus.prometheusOperator.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].values[0]"
    value = "infra"
  }



  ########################
  # Grafana              #
  ########################

  set {
    name  = "grafana.defaultDashboardsTimezone"
    value = "Europe/Paris"
  }

  set_sensitive {
    name  = "grafana.adminPassword"
    value = random_password.password.result
  }

  set {
    name  = "grafana.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight"
    value = "100"
  }

  set {
    name  = "grafana.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key"
    value = "node.type"
  }

  set {
    name  = "grafana.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].operator"
    value = "In"
  }

  set {
    name  = "grafana.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].values[0]"
    value = "infra"
  }

  ########################
  # Alertmanager         #
  ########################

  set {
    name  = "alertmanager.alertmanagerSpec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight"
    value = "100"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key"
    value = "node.type"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].operator"
    value = "In"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].values[0]"
    value = "infra"
  }

  ########################
  # kube-state-metrics   #
  ########################
  # In order to get annotations on kube_namespace_annotations metrics, we need to allow it on kube-state-metrics
  # https://github.com/kubernetes/kube-state-metrics/issues/1582
  set {
    name  = "kube-state-metrics.metricAnnotationsAllowList[0]"
    value = "namespaces=[*]"
  }

}
