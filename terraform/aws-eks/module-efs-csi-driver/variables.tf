#
# Cycloid
#

variable "project" {
  type        = string
  description = "Cycloid project name."
}

variable "env" {
  type        = string
  description = "Cycloid environment name."
}

variable "organization" {
  type        = string
  description = "Cycloid organization name."
}


variable "extra_tags" {
  type        = map(string)
  description = "Extra tags to add to the resources."
  default     = {}
}

#
# Module
#

variable "eks_node_desired_size" {}

variable "service_account_name" {
  default = "efs-csi-sa"
}

variable "namespace" {
  default = "kube-system"
}

variable "cluster_identity_oidc_issuer" {}
variable "cluster_identity_oidc_issuer_arn" {}

variable "storage_class_name" {
  default = "efs-sc"
}
