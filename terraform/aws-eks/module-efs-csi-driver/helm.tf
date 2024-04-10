# https://github.com/kubernetes-sigs/aws-efs-csi-driver/tree/master/charts/aws-efs-csi-driver
# https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/charts/aws-efs-csi-driver/CHANGELOG.md
# https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/CHANGELOG-1.x.md
resource "helm_release" "efs_csi_driver" {
  name       = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  version    = "2.5.7"
  namespace  = var.namespace

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.efs_csi_driver.arn
  }

  set {
    name  = "controller.serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name = "node.serviceAccount.create"
    # We're using the same service account for both the nodes and controllers,
    # and we're already creating the service account in the controller config
    # above.
    value = "false"
  }

  set {
    name  = "node.serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name  = "node.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.efs_csi_driver.arn
  }

  set {
    name  = "replicaCount"
    value = var.eks_node_desired_size > 1 ? 2 : 1
  }

  values = [
    file("${path.module}/values.yaml")
  ]
}
