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

locals {
  service_account_name = "${var.project}-${var.env}-aws-lb-controller"
}

#
# Module
#

variable "namespace" {
  default = "infra"
}

variable "cluster_identity_oidc_issuer" {}
variable "cluster_identity_oidc_issuer_arn" {}

variable "eks_node_desired_size" {}
variable "cluster_name" {}

variable "ingress_controller_svc_name" {}
