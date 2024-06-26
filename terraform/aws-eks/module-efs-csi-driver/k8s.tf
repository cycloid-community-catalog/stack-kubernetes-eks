resource "kubernetes_storage_class_v1" "efs-sc" {
  metadata {
    name = var.storage_class_name
  }

  # $$ is used to escape char with terraform
  parameters = {
    subPathPattern = "/$${.PVC.namespace}/$${.PVC.name}"
  }
  storage_provisioner = "efs.csi.aws.com"
}
