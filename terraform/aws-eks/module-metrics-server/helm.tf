################################################################################
# Helm-release: metrics-server
################################################################################
# Used to provide Horizontal Pod Autoscaling: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

# https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server
#VALUES: https://raw.githubusercontent.com/kubernetes-sigs/metrics-server/master/charts/metrics-server/values.yaml
# Metric server used to do Horizontal Pod Autoscaler

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.11.0"
  namespace  = var.namespace

  values = [
    file("${path.module}/values.yaml")
  ]

  # set {
  #   name  = "replicas"
  #   value = var.eks_node_desired_size > 1 ? 2 : 1
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
