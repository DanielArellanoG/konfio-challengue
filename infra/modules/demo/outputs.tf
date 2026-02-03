output "alb_arn" {
  value       = local.use_alb ? aws_lb.this[0].arn : null
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "endpoint" {
  value = (
    local.use_alb
    ? aws_lb.this[0].dns_name
    : aws_apigatewayv2_api.this[0].api_endpoint
  )
}

# output "ecs_services" {
#   value = {
#     loan_api = aws_ecs_service.loan_api.name #?????
#   }
# }
