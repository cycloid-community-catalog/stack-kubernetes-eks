################################################################################
# IAM role: creates permissions so the pod can create/delete Route53 records
################################################################################

# https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md#iam-policy

# Create policy
data "aws_iam_policy_document" "external_dns" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:route53:::hostedzone/*"]
    actions   = ["route53:ChangeResourceRecordSets"]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
  }
}

resource "aws_iam_policy" "external_dns" {
  name        = "${var.project}-${var.env}-external-dns"
  path        = "/"
  description = "Permissions for External-DNS on Route53"
  policy      = data.aws_iam_policy_document.external_dns.json
}

# Create role
data "aws_iam_policy_document" "external_dns_assume" {

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_identity_oidc_issuer_arn]
    }

    condition {
      test = "StringEquals"

      variable = "${var.cluster_identity_oidc_issuer}:sub"

      values = [
        "system:serviceaccount:${var.namespace}:${var.service_account_name}",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.project}-${var.env}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}
