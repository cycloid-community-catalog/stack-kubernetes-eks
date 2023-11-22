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
  default = "kube-system"
}

variable "service_account_name" {
  default = "fluent-bit-sa"
}


variable "cw_retention_in_days" {
  description = "Cloudwatch retention in days, by default 90 days(3 months)."
  default     = 90
}

variable "aws_region" {
  type        = string
  description = "The AWS region for CloudWatch."
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster where to use for the deployment."
}

variable "cluster_identity_oidc_issuer" {
  type        = string
  description = "The OpenID Connect identity provider (issuer URL without leading https://)."
}

variable "cluster_identity_oidc_issuer_arn" {
  type        = string
  description = "The ARN of the OIDC Provider."
}

################################################################################
# Local vars
################################################################################

locals {
  # cloud watch group name
  cw_log_group_name = "${var.cluster_name}-pods"
}

variable "fluentbit_enabled" {
  default = false
}
