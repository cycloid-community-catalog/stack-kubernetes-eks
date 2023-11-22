################################################################################
# Helm-release: Fluent bit
################################################################################
# generic one: https://github.com/fluent/helm-charts
# aws one: https://github.com/aws/eks-charts/tree/master/stable/aws-for-fluent-bit
#VALUES: https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-for-fluent-bit/values.yaml
resource "helm_release" "fluent-bit" {
  count      = var.fluentbit_enabled ? 1 : 0
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = "0.1.32"
  namespace  = var.namespace

  values = [
    file("${path.module}/values.yaml")
  ]

  # disable plugins for services not required
  set {
    name  = "firehose.enabled"
    value = false
  }
  set {
    name  = "kinesis.enabled"
    value = false
  }
  set {
    name  = "elasticsearch.enabled"
    value = false
  }

  # configure IAM permissions to make calls to AWS APIs using service account
  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.fluent-bit[0].arn
  }

  # configure cloudwatch
  set {
    name  = "cloudWatch.region"
    value = var.aws_region
  }
  set {
    name  = "cloudWatch.logGroupName"
    value = local.cw_log_group_name
  }
  # disable default logstreamprefix
  set {
    name  = "cloudWatch.logStreamPrefix"
    value = ""
  }

  # Example of Metadata variables available
  # {
  #     "kubernetes": {
  #         "annotations": {
  #             "checksum/config": "197a05362a5a8f7c7d7c340783760d4af6044b9d84f4632941ecd8d1a9c3726c",
  #             "kubernetes.io/psp": "eks.privileged"
  #         },
  #         "container_image": "public.ecr.aws/aws-observability/aws-for-fluent-bit:2.21.5",
  #         "container_name": "aws-for-fluent-bit",
  #         "docker_id": "c2dee352a1b3e4222ed661180f5446d704c74aa34ee0efc3d9106a95cc72467a",
  #         "host": "ip-10-1-1-28.eu-west-3.compute.internal",
  #         "labels": {
  #             "app.kubernetes.io/instance": "aws-for-fluent-bit",
  #             "app.kubernetes.io/name": "aws-for-fluent-bit",
  #             "controller-revision-hash": "654588f95c",
  #             "pod-template-generation": "2"
  #         },
  #         "namespace_name": "kube-system",
  #         "pod_id": "3d342ddc-98f5-4b2d-bd49-bb3d48383a62",
  #         "pod_name": "aws-for-fluent-bit-czwjf"
  #     },
  #     "log": "2022-07-18T11:12:44.160425613Z stdout F time=\"2022-07-18T11:12:44Z\" level=error msg=\"[cloudwatch 0] Encountered error ResourceNotFoundException: The specified log stream does not exist.; detailed information: The specified log stream does not exist.\\n\""
  # }

  set {
    name  = "cloudWatch.logStreamName"
    value = "$(kubernetes['namespace_name'])/$(kubernetes['pod_name'])/$(kubernetes['container_name'])"
  }

  # exclude some pods logs (can't find the right syntax)
  #   set {
  #     name  = "cloudWatch.input.extraInputs"
  #     value = <<EOF
  #     |
  #      Exclude_Path /var/log/containers/*-csi-*, /var/log/containers/*fluent-bit*, /var/log/containers/aws-node*, /var/log/containers/kube-proxy*
  # EOF
  #  }

  # To exclude from pods, it is possible to use annotation (https://docs.fluentbit.io/manual/pipeline/filters/kubernetes#request-to-exclude-logs)
  # annotations:
  #   fluentbit.io/exclude: "true"

  # or namespace via https://stackoverflow.com/questions/57027935/how-to-exclude-namespace-from-fluent-bit-logging
}
