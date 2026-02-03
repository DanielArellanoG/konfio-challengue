resource "aws_lb" "this" {
  count              = local.use_alb ? 1 : 0
  name               = "loan-alb-${var.environment}"
  load_balancer_type = "application"
  internal           = false
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_listener" "http" {
  count = local.use_alb ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loan_api.arn
  }
}
