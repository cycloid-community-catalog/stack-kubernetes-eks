################################################################################
# AWS Provider - to create aws resources
################################################################################

provider "aws" {
  region = var.aws_region
  # credentials set as env vars by pipeline
  default_tags {
    tags = {
      "cycloid.io" = "true"
      env          = var.env
      project      = var.project
      client       = var.organization
      organization = var.organization
    }
  }
}

# Get an authentication token to communicate with an EKS cluster using IAM credentials from the AWS provider
# data "aws_eks_cluster_auth" "eks" {
#   name = module.eks.cluster_id
# }

# Get the access to the effective Account ID, User ID, and ARN in which Terraform is authorized.
data "aws_caller_identity" "current" {}

################################################################################
# K8s Provider - provides connection to the created cluster
################################################################################

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  # token                  = data.aws_eks_cluster_auth.eks.token
  # Force refresh token to not expire after 15min
  # https://github.com/hashicorp/terraform-provider-kubernetes/issues/1131
  # since cc terraform image doesn't have awscli installed, here is a workaround
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   args    = ["-c", "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip 2> /dev/null; unzip -o awscliv2.zip > /dev/null; ./aws/install --update 2>1 > /dev/null; /usr/local/bin/aws eks get-token --cluster-name ${module.eks.cluster_id}"]
  #   command    = "/bin/bash"
  # }
}

################################################################################
# Helm Provider - allows to use helm charts to deploy software in the cluster
################################################################################

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    # token                  = data.aws_eks_cluster_auth.eks.token
    # Force refresh token to not expire after 15min
    # https://github.com/hashicorp/terraform-provider-kubernetes/issues/1131
    # since cc terraform image doesn't have awscli installed, here is a workaround
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

################################################################################
# Kubectl Provider - allows to use YAML manifest inside Terraform ressource declaration
################################################################################

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 3
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  # token                  = data.aws_eks_cluster_auth.eks.token
  load_config_file = false

  # Force refresh token to not expire after 15min
  # https://github.com/hashicorp/terraform-provider-kubernetes/issues/1131
  # since cc terraform image doesn't have awscli installed, here is a workaround
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}
