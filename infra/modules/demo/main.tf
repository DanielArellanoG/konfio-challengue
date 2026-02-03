locals {
  name_prefix = "loans-${var.environment}-stack"
  use_alb   = var.entrypoint_type == "alb"
  use_apigw = var.entrypoint_type == "apigw"
}
