################################################################################
# Storage class definition, to be used to dynamically provisioned EBS volumes
################################################################################
resource "kubernetes_storage_class_v1" "ebs-sc" {
  metadata {
    name = var.storage_class_name

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  reclaim_policy = "Delete"

  storage_provisioner = "ebs.csi.aws.com"
  # recommended mode delays the binding and provisioning of a PersistentVolume until a Pod using the PersistentVolumeClaim is created
  # more details here: https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode
  volume_binding_mode = "WaitForFirstConsumer"
}
# kubectl patch storageclass ebs-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
