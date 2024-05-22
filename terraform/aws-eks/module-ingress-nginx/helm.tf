################################################################################
# Helm-release: Ingress controller(lb) using NGINX
################################################################################
# https://kubernetes.github.io/ingress-nginx/
# https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx
# https://github.com/kubernetes/ingress-nginx/tree/main?tab=readme-ov-file#supported-versions-table
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.1"
  namespace  = var.namespace

  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "controller.service.enabled"
    value = false
  }

  set {
    name  = "controller.replicaCount"
    value = var.eks_node_desired_size > 1 ? 2 : 1
  }

  set {
    name  = "controller.config.enable-real-ip"
    value = "true"
  }

  # other possible config
  # enable-brotli: 'true'
  # custom-http-errors: '500,502,503,504'
  # use-forwarded-headers: "true"
  # real-ip-header: X-Forwarded-For
  # real-ip-header: "proxy_protocol"
  # set-real-ip-from: 0.0.0.0/0
  # proxy-real-ip-cidr: 10.0.0.0/8
  # use-proxy-protocol: 'true'

  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }

  # Allows overriding of the publish service to bind to
  # Must be <namespace>/<service_name>
  # Since the NLB is created by aws-loadbalancer-controller, make sure the nginx use the service nlb to define the loadbalancer ip as ingress address
  # set {
  #   name  = "controller.publishService.pathOverride"
  #   value = "${var.namespace}/${var.ingress_controller_svc_name}"
  # }
  # /!\ publishService can't be set service not enabled (https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/templates/_params.tpl#L6)
  # so we use extraArgs to define it
  set {
    name  = "controller.extraArgs.publish-service"
    value = "${var.namespace}/${var.ingress_controller_svc_name}"
  }

  # set {
  #   name  = "admissionWebhooks.metrics.enabled"
  #   value = "true"
  # }
  # set {
  #   name  = "admissionWebhooks.metrics.prometheusRule.enabled"
  #   value = "true"
  # }

  # Other changes on the config from the default value
  # [default] updateStrategy: {}
  # [default] affinity: {}
  # [default] annotations: {}
  # [default] metrics.prometheusRule.rules: []
}
