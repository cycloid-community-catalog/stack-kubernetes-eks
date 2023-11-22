# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/service/annotations/

# Create a service LoadBalancer wich is used by aws controller to create a NLB
# This NLB is used to redirect trafic to nginx ingress controller
resource "kubernetes_service" "ingress-controller" {
  metadata {
    name      = var.ingress_controller_svc_name
    namespace = var.namespace

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
      # "service.beta.kubernetes.io/aws-load-balancer-target-group-attributes" = "proxy_protocol_v2.enabled=true"
      "service.beta.kubernetes.io/aws-load-balancer-target-group-attributes"           = "preserve_client_ip.enabled=true"
      "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"                  = "tcp"
      "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
      # "service.beta.kubernetes.io/aws-load-balancer-proxy-protocol"                    = "*"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/component" : "controller"
      "app.kubernetes.io/instance" : "ingress-nginx"
      "app.kubernetes.io/name" : "ingress-nginx"
    }

    port {
      name        = "http"
      node_port   = 30080
      port        = 80
      protocol    = "TCP"
      target_port = "http"
    }

    port {
      name        = "https"
      node_port   = 30443
      port        = 443
      protocol    = "TCP"
      target_port = "https"
    }

    type = "LoadBalancer"
  }

  depends_on = [
    time_sleep.wait_destroy
  ]
}
