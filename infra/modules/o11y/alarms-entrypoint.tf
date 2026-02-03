resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = local.use_alb ? 1 : 0

  alarm_name          = "alb-${var.environment}-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = var.thresholds.alb_5xx_rate
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  count = local.use_apigw ? 1 : 0

  alarm_name          = "apigw-${var.environment}-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = var.thresholds.apigw_5xx_rate
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"

  dimensions = {
    ApiId = var.apigw_api_id
    Stage = var.environment
  }

  alarm_actions = local.alarm_actions
}
