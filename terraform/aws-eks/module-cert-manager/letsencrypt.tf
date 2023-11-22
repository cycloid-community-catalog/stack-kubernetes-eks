# https://cert-manager.io/docs/configuration/acme/#dns-zones
# dnsZones should match domain and subdomains

resource "kubectl_manifest" "letsencrypt-staging-dns01" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging-dns01
  namespace: infra
spec:
  acme:
    email: ${var.contact_email}
    privateKeySecretRef:
      name: letsencrypt-staging-dns01
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    solvers:
    - dns01:
        route53:
          region: ${var.aws_region}
      selector:
        dnsZones:
        - ${var.managed_domain}
YAML
  depends_on = [
    helm_release.cert_manager,
    aws_iam_role_policy_attachment.cert_manager
  ]
}


resource "kubectl_manifest" "letsencrypt-prod-dns01" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod-dns01
  namespace: infra
spec:
  acme:
    email: ${var.contact_email}
    privateKeySecretRef:
      name: letsencrypt-prod-dns01
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    - dns01:
        route53:
          region: ${var.aws_region}
      selector:
        dnsZones:
        - ${var.managed_domain}
YAML
  depends_on = [
    helm_release.cert_manager,
    aws_iam_role_policy_attachment.cert_manager
  ]
}


resource "kubectl_manifest" "letsencrypt-staging-http01" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging-http01
  namespace: infra
spec:
  acme:
    email: ${var.contact_email}
    privateKeySecretRef:
      name: letsencrypt-staging-http01
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    solvers:
    - http01:
        ingress:
          class: nginx
YAML
  depends_on = [
    helm_release.cert_manager,
    aws_iam_role_policy_attachment.cert_manager
  ]
}


resource "kubectl_manifest" "letsencrypt-prod-http01" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod-http01
  namespace: infra
spec:
  acme:
    email: ${var.contact_email}
    privateKeySecretRef:
      name: letsencrypt-prod-http01
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    - http01:
        ingress:
          class: nginx
YAML
  depends_on = [
    helm_release.cert_manager,
    aws_iam_role_policy_attachment.cert_manager
  ]
}
