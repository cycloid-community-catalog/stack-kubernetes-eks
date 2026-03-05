# https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/example-iam-policy.json
# https://flosell.github.io/iam-policy-json-to-terraform/

data "aws_iam_policy_document" "ebs_csi_driver" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVolumeStatus",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]

    actions = [
      "ec2:CreateSnapshot",
      "ec2:ModifyVolume",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/vol-*"]
    actions   = ["ec2:CopyVolumes"]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:instance/*",
    ]

    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:snapshot/*"]

    actions = [
      "ec2:CreateVolume",
      "ec2:EnableFastSnapshotRestores",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*",
    ]

    actions = ["ec2:CreateTags"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"

      values = [
        "CreateVolume",
        "CreateSnapshot",
        "CopyVolumes",
      ]
    }
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*",
    ]

    actions = ["ec2:DeleteTags"]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]

    actions = [
      "ec2:CreateVolume",
      "ec2:CopyVolumes",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]

    actions = [
      "ec2:CreateVolume",
      "ec2:CopyVolumes",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]
    actions   = ["ec2:DeleteVolume"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]
    actions   = ["ec2:DeleteVolume"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]
    actions   = ["ec2:DeleteVolume"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/kubernetes.io/created-for/pvc/name"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    actions   = ["ec2:CreateSnapshot"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeSnapshotName"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    actions   = ["ec2:CreateSnapshot"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    actions   = ["ec2:DeleteSnapshot"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    actions   = ["ec2:DeleteSnapshot"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "ebs_csi_driver" {
  name        = "${var.project}-${var.env}-ebs-csi-driver"
  path        = "/"
  description = "Policy for the ebs CSI driver"

  policy = data.aws_iam_policy_document.ebs_csi_driver.json
}

# Create role
data "aws_iam_policy_document" "ebs_csi_driver_assume" {

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
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.project}-${var.env}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume.json
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = aws_iam_policy.ebs_csi_driver.arn
}
