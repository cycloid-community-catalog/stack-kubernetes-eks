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

variable "prometheus_enabled" {
  default = false
}

variable "storage_class_name" {
  type        = string
  description = "EBS storage class to store prometheus datas."
}

variable "secret_basic_auth_infra_name" {
  type        = string
  description = "Basic auth secret name to use."
}

variable "prometheus_pvc_size" {
  default = 80
}

resource "random_password" "password" {
  length  = 32
  special = false
}

# output "monitoring_password" {
#   sensitive = true
#   value     = { "grafana" : { "user" : "admin", "password" : random_password.password.result } }
# }
#
# output "monitoring_urls" {
#   value = { for k in local.service_enabled : k => "${k}.${var.project}-${var.env}.phrasea.io" }
# }

output "monitoring_access" {
  sensitive = true
  value = { for k in local.service_enabled :
    k => {
      url : "https://${k}.${var.project}-${var.env}.phrasea.io",
      "user" : "admin",
      "password" : random_password.password.result
    }
  }
}
