locals {
  use_alb   = var.entrypoint_type == "alb"
  use_apigw = var.entrypoint_type == "apigw"

  alarm_actions = var.alarm_sns_topic_arn != null
    ? [var.alarm_sns_topic_arn]
    : []
}
