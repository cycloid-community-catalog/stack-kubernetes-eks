resource "kubernetes_storage_class" "efs-sc" {
  metadata {
    name = var.storage_class_name
  }

  parameters = {
    subPathPattern = "/${.PVC.namespace}/${.PVC.name}"
  }
  storage_provisioner = "efs.csi.aws.com"
}
