################################################################################
# Cloud watch log groups for the log streams from fluent bit
################################################################################

resource "aws_cloudwatch_log_group" "fluentbit" {
  count             = var.fluentbit_enabled ? 1 : 0
  name              = local.cw_log_group_name
  retention_in_days = var.cw_retention_in_days
}
