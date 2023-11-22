################################################################################
# Cycloid vars
################################################################################
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

################################################################################
# Module vars
################################################################################
variable "service_account_name" {
  description = "Name of the service account to use to manage the lifecyle of EBS ."
  default     = "ebs-csi-sa"
}

variable "namespace" {
  description = "Namespace where to deploy drivers."
  default     = "kube-system"
}

variable "eks_node_desired_size" {
  type        = number
  description = "Number of nodes of the EKS."
}

variable "storage_class_name" {
  description = "The name to give to the EBS storage class."
  default     = "ebs-sc"
}

variable "cluster_identity_oidc_issuer" {
  type        = string
  description = "The OpenID Connect identity provider (issuer URL without leading https://)."
}

variable "cluster_identity_oidc_issuer_arn" {
  type        = string
  description = "The ARN of the OIDC Provider."
}
