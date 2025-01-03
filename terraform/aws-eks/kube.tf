################################################################################
# Modules not to be changed by .forms, since they changes less frequently
################################################################################

# Make sure EKS node destroyed after k8s resources
resource "time_sleep" "wait_eks_destroy" {
  depends_on       = [module.eks]
  destroy_duration = "3m"
}

################################################################################
# Module eks-auth - Configuration in this directory creates/updates the aws-auth ConfigMap.
# https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/aws-auth
################################################################################
# Configmap is use to make a link between iam role and k8s cluster role

# Wait few minutes after EKS cluster is created to ensure aws-auth configmap is created
resource "time_sleep" "wait_eks" {
  depends_on      = [module.eks]
  create_duration = "1m"
}

# Wait NLB, makes sure it is created
resource "time_sleep" "wait_nlb" {
  depends_on      = [module.aws-load-balancer-controller]
  create_duration = "2m"
}

module "eks-auth" {
  depends_on = [
    time_sleep.wait_eks
  ]
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.31.6"

  # Creates aws-auth configmap - to enable acces to cluster using IAM
  manage_aws_auth_configmap = true
  # list of role maps to add to the aws-auth configmap
  aws_auth_roles = local.aws_auth_roles
}

################################################################################
# Module aws-load-balancer-controller - manage ingress/service as aws alb/nlb
# helm chart at https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller
################################################################################
# This controller is used to create NLB on top of the nginx ingress controller.
# we use it to manage more available option on NLB which is not available with nginx controller
module "aws-load-balancer-controller" {
  #####################################
  # Do not modify the following lines #
  source = "./module-aws-load-balancer-controller"

  project      = var.project
  env          = var.env
  organization = var.organization
  #####################################

  namespace                   = kubernetes_namespace_v1.infra.metadata.0.name
  ingress_controller_svc_name = var.ingress_controller_svc_name

  # used to define if we need more than 1 nginx
  eks_node_desired_size            = var.node_desired_size
  cluster_identity_oidc_issuer     = module.eks.oidc_provider
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  cluster_name                     = module.eks.cluster_name

  depends_on = [
    time_sleep.wait_eks_destroy
  ]
}

################################################################################
# Module ingress-nginx - Ingress controller(lb) using NGINX
# helm chart at https://github.com/kubernetes/ingress-nginx
################################################################################

module "ingress-nginx" {
  #####################################
  # Do not modify the following lines #
  source       = "./module-ingress-nginx"
  project      = var.project
  env          = var.env
  organization = var.organization
  #####################################

  namespace                   = kubernetes_namespace_v1.infra.metadata.0.name
  ingress_controller_svc_name = var.ingress_controller_svc_name

  # used to define if we need more than 1 nginx
  eks_node_desired_size = var.node_desired_size

  # eks_managed_node_groups_autoscaling_group_names = module.eks.eks_managed_node_groups_autoscaling_group_names
  depends_on = [
    module.aws-load-balancer-controller,
    time_sleep.wait_nlb
  ]
}


################################################################################
# Module cert-manager - cert-manager is a Kubernetes addon to automate the management and issuance of TLS certificates from various issuing source
# helm chart at https://artifacthub.io/packages/helm/cert-manager/cert-manager
################################################################################

module "cert-manager" {
  #####################################
  # Do not modify the following lines #
  source       = "./module-cert-manager"
  project      = var.project
  env          = var.env
  organization = var.organization
  #####################################

  namespace                        = kubernetes_namespace_v1.infra.metadata.0.name
  service_account_name             = "cert-manager"
  aws_region                       = var.aws_region
  cluster_id                       = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.oidc_provider
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  managed_domain                   = var.managed_domain

  depends_on = [
    module.eks,
    time_sleep.wait_nlb
  ]
}

################################################################################
# Module external-dns - creates pod that reads ingress/Services and creates DNS records
# helm chart at https://github.com/bitnami/charts/tree/master/bitnami/external-dns
################################################################################

module "external-dns" {
  #####################################
  # Do not modify the following lines #
  source       = "./module-external-dns"
  project      = var.project
  env          = var.env
  organization = var.organization
  #####################################

  namespace                        = kubernetes_namespace_v1.infra.metadata.0.name
  service_account_name             = "external-dns-${var.env}"
  cluster_id                       = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.oidc_provider
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn

  managed_domain = var.managed_domain

  depends_on = [
    module.eks
  ]
}


################################################################################
# Module ebs-csi-driver - allows to manage EBS lifecycle
# helm chart at https://github.com/kubernetes-sigs/aws-ebs-csi-driver
################################################################################

module "ebs-csi-driver" {
  #####################################
  # Do not modify the following lines #
  source       = "./module-ebs-csi-driver"
  project      = var.project
  env          = var.env
  organization = var.organization
  #####################################

  # used to define if we need more than 1 nginx
  eks_node_desired_size = var.node_desired_size

  cluster_identity_oidc_issuer     = module.eks.oidc_provider
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn

  depends_on = [
    time_sleep.wait_eks_destroy,
    module.eks-auth
  ]
}

module "efs-csi-driver" {
  #####################################
  # Do not modify the following lines #
  source = "./module-efs-csi-driver"

  project      = var.project
  env          = var.env
  organization = var.organization
  #####################################

  # used to define if we need more than 1 nginx
  eks_node_desired_size = var.node_desired_size

  cluster_identity_oidc_issuer     = module.eks.oidc_provider
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn

  depends_on = [
    time_sleep.wait_eks_destroy,
    module.eks-auth
  ]
}

################################################################################
# Module prometheus - scrapes k8s metrics and stores in EBS
# helm chart at https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus
################################################################################

resource "time_sleep" "wait_ebs_destroy" {
  depends_on = [module.ebs-csi-driver]
  # create_duration = "30s"
  destroy_duration = "3m"
}

resource "time_sleep" "wait_ingress" {
  depends_on      = [module.ingress-nginx]
  create_duration = "1m"
}

module "monitoring" {
  #####################################
  # Do not modify the following lines #
  source = "./module-kube-prometheus-stack"

  project      = var.project
  env          = var.env
  organization = var.organization
  #####################################

  prometheus_enabled           = var.prometheus_enabled
  namespace                    = kubernetes_namespace_v1.infra.metadata.0.name
  storage_class_name           = module.ebs-csi-driver.storage_class_name
  prometheus_pvc_size          = var.prometheus_pvc_size
  secret_basic_auth_infra_name = var.secret_basic_auth_infra_name
  depends_on = [
    time_sleep.wait_ebs_destroy,
    time_sleep.wait_ingress
  ]
}

# Prometheus blackbox exporter. Used to scrape URL/Ingresses metrics
module "blackbox" {
  #####################################
  # Do not modify the following lines #
  source = "./module-prometheus-blackbox-exporter"

  project      = var.project
  env          = var.env
  organization = var.organization
  #####################################

  namespace = kubernetes_namespace_v1.infra.metadata.0.name
}

################################################################################
# Module fluent-bit - collects logs and send them to cloudwatch
# AWS helm chart at https://github.com/aws/eks-charts/tree/master/stable/aws-for-fluent-bit
# Note! Generic one: https://github.com/fluent/helm-charts
################################################################################
module "fluent-bit" {
  #####################################
  # Do not modify the following lines #
  source = "./module-fluent-bit"

  project      = var.project
  env          = var.env
  organization = var.organization
  #####################################

  fluentbit_enabled                = var.fluentbit_enabled
  namespace                        = kubernetes_namespace_v1.infra.metadata.0.name
  aws_region                       = var.aws_region
  cluster_name                     = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.oidc_provider
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
}

################################################################################
# Module metrics-server - Provide metrics used for Horizontal Pod Autoscaler
# helm chart at https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server
################################################################################
module "module-metrics-server" {
  #####################################
  # Do not modify the following lines #
  source = "./module-metrics-server"

  project      = var.project
  env          = var.env
  organization = var.organization
  #####################################

  namespace = kubernetes_namespace_v1.infra.metadata.0.name

  # used to define if we need more than 1 pod
  # eks_node_desired_size            = var.node_desired_size
}
