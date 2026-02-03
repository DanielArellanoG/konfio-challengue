resource "aws_apigatewayv2_api" "this" {
  count = local.use_apigw ? 1 : 0

  name          = "loan-api-${var.environment}"
  protocol_type = "HTTP"
}

resource "aws_lb" "nlb" {
  count = local.use_apigw ? 1 : 0
  load_balancer_type = "network"
  subnets            = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_lb_listener" "nlb" {
  count = local.use_apigw ? 1 : 0

  load_balancer_arn = aws_lb.nlb[0].arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loan_api.arn
  }
}

resource "aws_apigatewayv2_vpc_link" "this" {
  count = local.use_apigw ? 1 : 0
  name = "${var.environment}-apigw-vpc-link"
  subnet_ids = aws_subnet.private_app[*].id
  security_group_ids = [aws_security_group.vpc_link[0].id]
}

resource "aws_apigatewayv2_integration" "this" {
  count = local.use_apigw ? 1 : 0

  api_id           = aws_apigatewayv2_api.this[0].id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.nlb[0].arn

  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.this[0].id
}
