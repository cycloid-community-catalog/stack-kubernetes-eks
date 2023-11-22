resource "kubernetes_storage_class" "efs-sc" {
  metadata {
    name = var.storage_class_name
  }

  storage_provisioner = "efs.csi.aws.com"
}
