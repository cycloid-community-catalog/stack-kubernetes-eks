# https://github.com/kubernetes-sigs/aws-ebs-csi-driver
# https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/CHANGELOG.md
################################################################################
# Helm-release: EBS CSI driver
################################################################################

resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
  chart      = "aws-ebs-csi-driver"
  version    = "2.54.1"
  namespace  = var.namespace

  # values = [
  #   file("${path.module}/values.yaml")
  # ]

  set = [
    # set controller plugin count to deploy (one per node)
    {
      name  = "controller.replicaCount"
      value = var.eks_node_desired_size > 1 ? 2 : 1
    },

    # configure IAM permissions to make calls to AWS APIs using service account
    # for the controller plugin and the node plugin
    # set default create service account to false
    {
      name = "node.serviceAccount.create"
      # We're using the same service account for both the nodes and controllers plugins,
      # and the service account will be created inthe controller config
      value = "false"
    },

    # service account controller plugin
    {
      name  = "controller.serviceAccount.name"
      value = var.service_account_name
    },
    {
      name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.ebs_csi_driver.arn
    },

    # service account node plugin
    {
      name  = "node.serviceAccount.name"
      value = var.service_account_name
    },
    {
      name  = "node.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.ebs_csi_driver.arn
    }
  ]
}
