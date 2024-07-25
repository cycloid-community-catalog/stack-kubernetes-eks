################################################################################
# Helm-release: metrics-server
################################################################################
# Used to provide Horizontal Pod Autoscaling: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
# https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server
# https://github.com/kubernetes-sigs/metrics-server/blob/master/charts/metrics-server/CHANGELOG.md

# Metric server used to do Horizontal Pod Autoscaler

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.1"
  namespace  = var.namespace

  # values = [
  #   file("${path.module}/values.yaml")
  # ]

  # set {
  #   name  = "replicas"
  #   value = var.eks_node_desired_size > 1 ? 2 : 1
  # }
}
