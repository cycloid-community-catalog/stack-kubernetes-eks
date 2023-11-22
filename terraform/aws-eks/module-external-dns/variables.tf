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

variable "namespace" {
  default = "infra"
}

variable "service_account_name" {
  default = "external-dns"
}

variable "cluster_id" {
  type        = string
  description = "The id of the EKS cluster."
}

variable "cluster_identity_oidc_issuer" {
  type        = string
  description = "The OpenID Connect identity provider (issuer URL without leading https://)."
}

variable "cluster_identity_oidc_issuer_arn" {
  type        = string
  description = "The ARN of the OIDC Provider."
}

variable "managed_domain" {
  type        = string
  description = "cycloid.io"
}
