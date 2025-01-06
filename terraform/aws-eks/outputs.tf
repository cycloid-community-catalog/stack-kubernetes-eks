# EKS

# locals {
#   kubeconfig = yamlencode({
#     apiVersion      = "v1"
#     kind            = "Config"
#     current-context = "terraform"
#     clusters = [{
#       name = module.eks.cluster_id
#       cluster = {
#         certificate-authority-data = module.eks.cluster_certificate_authority_data
#         server                     = module.eks.cluster_endpoint
#       }
#     }]
#     contexts = [{
#       name = "terraform"
#       context = {
#         cluster = module.eks.cluster_id
#         user    = "terraform"
#       }
#     }]
#     users = [{
#       name = "terraform"
#       user = {
#         token = data.aws_eks_cluster_auth.eks.token
#       }
#     }]
#   })
# }
#
# output "kubeconfig" {
#   description = "AWS region to launch servers."
#   sensitive   = true
#   value       = local.kubeconfig
# }

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region to launch servers."
  value       = var.aws_region
}

output "cluster_id" {
  value       = "${var.project}-${var.env}"
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready."
}

output "cluster_id_simple" {
  value       = try(module.eks.cluster_id, "")
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready."
}

output "cluster_name" {
  value       = try(module.eks.cluster_name, "")
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready."
}

output "cluster_version" {
  value       = module.eks.cluster_version
  description = "The Kubernetes version for the cluster."
}

output "cluster_iam_role_name" {
  value = module.eks.cluster_iam_role_name
}

output "eks_managed_node_groups_autoscaling_group_names" {
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
  description = "List of the autoscaling group names created by EKS managed node groups"
}

output "cluster_arn" {
  value       = module.eks.cluster_arn
  description = "The Amazon Resource Name (ARN) of the cluster"
}

output "cluster_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
}

output "oidc_provider" {
  value       = module.eks.oidc_provider
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
}

output "node_security_group_id" {
  value       = module.eks.node_security_group_id
  description = "ID of the node shared security group"
}


# VPC
# https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/outputs.tf
output "vpc_id" {
  description = "The ID of the VPC"
  value       = try(module.vpc.vpc_id, "")
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = try(module.vpc.vpc_cidr_block, "")
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = try(module.vpc.nat_public_ips, "")
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = try(module.vpc.private_subnets, "")
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = try(module.vpc.public_subnets, "")
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = try(module.vpc.database_subnets, "")
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = try(module.vpc.database_subnet_group, "")
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = try(module.vpc.database_subnet_group_name, "")
}

output "elasticache_subnet_group_name" {
  description = "Name of elasticache subnet group"
  value       = try(module.vpc.elasticache_subnet_group_name, "")
}

output "azs" {
  description = "A list of availability zones specified as argument to this module"
  value       = try(module.vpc.azs, "")
}

# ingress-nginx
output "ingress_nginx_lb_dns" {
  description = "The ingress-nginx AWS Load Balancer DNS name"
  value       = try(module.ingress-nginx.ingress_nginx_lb_dns, "")
}

# Secrets
output "k8s_secret_infra_basic_auth_user" {
  value = var.k8s_secret_infra_basic_auth_user
}

output "k8s_secret_infra_basic_auth_password" {
  sensitive = true
  value     = random_password.k8s_secret_infra_basic_auth_password.result
}

output "monitoring_access" {
  value     = try(module.monitoring.monitoring_access, "")
  sensitive = true
}

output "managed_domain" {
  value = var.managed_domain
}
