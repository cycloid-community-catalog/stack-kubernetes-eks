################################################################################
# IAM role: creates permissions to manage logs in cloudwatch
################################################################################

# Create policy
data "aws_iam_policy_document" "fluent-bit" {

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "fluent-bit" {
  count       = var.fluentbit_enabled ? 1 : 0
  name        = "${var.project}-${var.env}-fluent-bit"
  path        = "/"
  description = "Policy for fluent-bit"

  policy = data.aws_iam_policy_document.fluent-bit.json
}

# Create role
data "aws_iam_policy_document" "fluent-bit_assume" {

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
        "system:serviceaccount:${var.namespace}:${var.service_account_name}",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "fluent-bit" {
  count              = var.fluentbit_enabled ? 1 : 0
  name               = "${var.project}-${var.env}-fluent-bit"
  assume_role_policy = data.aws_iam_policy_document.fluent-bit_assume.json
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "fluent-bit" {
  count      = var.fluentbit_enabled ? 1 : 0
  role       = aws_iam_role.fluent-bit[0].name
  policy_arn = aws_iam_policy.fluent-bit[0].arn
}
