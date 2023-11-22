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

################################################################################
# Module vars
################################################################################
variable "namespace" {
  default = "infra"
}
