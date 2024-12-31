# https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller
# https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.11.0"
  namespace  = var.namespace

  # values = [
  #   file("${path.module}/values.yaml")
  # ]

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = local.service_account_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_lb_controller.arn
  }

  set {
    name  = "replicaCount"
    value = var.eks_node_desired_size > 1 ? 2 : 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_lb_controller
  ]
}

# wait svc delete before destroying driver
resource "time_sleep" "wait_destroy" {
  depends_on = [helm_release.aws_load_balancer_controller,
    aws_iam_role_policy_attachment.aws_lb_controller,
  aws_iam_role.aws_lb_controller]
  # create_duration = "30s"
  destroy_duration = "1m"
}
