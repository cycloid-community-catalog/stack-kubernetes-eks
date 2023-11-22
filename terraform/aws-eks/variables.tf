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

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-west-1"
}

variable "managed_domain" {
  description = "Domain used to configure cert & ingress."
  default     = "cycloid.io"
}

variable "keypair_name" {
  description = "Domain used to configure cert & ingress."
  default     = "cycloid"
}

variable "prometheus_pvc_size" {
  default = 10
}

################################################################################
# Stackforms vars
################################################################################

## EKS module

variable "node_desired_size" {
  default = 1
}

variable "node_max_size" {
  default = 10
}

variable "node_disk_size" {
  default = 50
}

variable "node_instance_type" {
  default = "t3.large"
}

variable "subnet_ip_digit" {
  default = "0"
}

variable "prometheus_enabled" {
  default = false
}

variable "fluentbit_enabled" {
  default = false
}

################################################################################
# Kubernetes vars
################################################################################

# We use aws-load-balancer-controller to create a NLB (with more options) via a service (ingress_controller_svc_name)
# The service is also used by nginx-ingress-controller to set ingress address with tge Loadbalancer ip
variable "ingress_controller_svc_name" {
  default = "ingress-nginx-controller"
}

# name of the secret used as basic auth for prometheus in the infra namespace
variable "secret_basic_auth_infra_name" {
  default = "basic-auth"
}

################################################################################
# Local vars
################################################################################

locals {

  # Get availabity zone from the list, if only 1 node only 1 az retrieved
  az_node_count = var.node_desired_size >= 3 ? 3 : var.node_desired_size

  # Get x az from the list. If customer only want 1 node, ensure it use the same AZ
  # azs_needed = slice(["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"], 0, local.az_node_count)
  subnet_ids_needed = slice(module.vpc.private_subnets, 0, local.az_node_count)

  # EKS IAM doesn't support mapping to group yet (https://github.com/aws/containers-roadmap/issues/150)
  # - Start by creating 2 IAM roles(eks_preprod | eks_prod) + 1 policy that allows to manage EKS and attached it to the roles
  # - Then we added the role in aws-auth configmap under the mapRoles section (done here with aws_auth_roles_default).
  # - Finally create a policy that allows assuming the role and attach it to your R&D group eks_preprod
  # https://eng.grip.security/enabling-aws-iam-group-access-to-an-eks-cluster-using-rbac

  # default admin roles
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin"
      username = "admin"
      groups   = ["system:masters"]
    },
  ]
}
