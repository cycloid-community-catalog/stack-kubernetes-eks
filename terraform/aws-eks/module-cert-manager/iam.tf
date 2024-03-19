# https://cert-manager.io/docs/configuration/acme/dns01/route53/#set-up-an-iam-role
# https://flosell.github.io/iam-policy-json-to-terraform/

data "aws_iam_policy_document" "cert_manager" {

  statement {
    actions = [
      "route53:GetChange"
    ]
    resources = [
      "arn:aws:route53:::change/*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "route53:ListHostedZonesByName"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"
  }

}

resource "aws_iam_policy" "cert_manager" {
  name        = "${var.project}-${var.env}-cert-manager"
  path        = "/"
  description = "Policy for cert-manager service"

  policy = data.aws_iam_policy_document.cert_manager.json
}

# Role
data "aws_iam_policy_document" "cert_manager_assume" {

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_identity_oidc_issuer_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.cluster_identity_oidc_issuer}:sub"

      values = [
        "system:serviceaccount:${var.namespace}:${var.service_account_name}"
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "cert_manager" {
  name               = "${var.project}-${var.env}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume.json
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager.arn
}
