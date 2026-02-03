resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "loan-api-${var.environment}-metrics-overview"

  dashboard_body = jsonencode({
    widgets = compact([
################# Traffic
      local.use_alb ? {
        type = "metric"
        properties = {
            title = "ALB Traffic (RequestCount)"
            period = 60
            metrics = [
            [
                "AWS/ApplicationELB",
                "RequestCount",
                "LoadBalancer",
                var.alb_arn_suffix,
                { "stat": "Sum" }
            ]
            ]
        }
      } : null,
      local.useapigw ? {
        type = "metric"
        properties = {
            title = "API Gateway Traffic (Count)"
            period = 60
            metrics = [
            [
                "AWS/ApiGateway",
                "Count",
                "ApiId",
                var.apigw_api_id,
                "Stage",
                var.environment,
                { "stat": "Sum" }
            ]
            ]
        }
      } : null,
################# Error rate
      local.use_alb ? {
        type = "metric"
        properties = {
            title = "ALB Error Rate (%)"
            period = 60
            stat = "Sum"
            metrics = [
            [
                "AWS/ApplicationELB",
                "HTTPCode_ELB_5XX_Count",
                "LoadBalancer",
                var.alb_arn_suffix,
                { "id": "e", "stat": "Sum" }
            ],
            [
                "AWS/ApplicationELB",
                "RequestCount",
                "LoadBalancer",
                var.alb_arn_suffix,
                { "id": "r", "stat": "Sum" }
            ],
            [
                {
                "expression": "(e / r) * 100",
                "label": "5XX Error Rate (%)",
                "id": "er",
                "region": "us-east-1"
                }
            ]
            ]
        }
      } : null,
      local.use_apigw ? {
        type = "metric"
        properties = {
            title = "API Gateway Error Rate (%)"
            period = 60
            metrics = [
            [
                "AWS/ApiGateway",
                "5XXError",
                "ApiId",
                var.apigw_api_id,
                "Stage",
                var.environment,
                { "id": "e", "stat": "Sum" }
            ],
            [
                "AWS/ApiGateway",
                "Count",
                "ApiId",
                var.apigw_api_id,
                "Stage",
                var.environment,
                { "id": "r", "stat": "Sum" }
            ],
            [
                {
                "expression": "(e / r) * 100",
                "label": "5XX Error Rate (%)",
                "id": "er"
                }
            ]
            ]
        }
      } : null,
################# Compute Latency
      local.use_alb ? {
        type = "metric"
        properties = {
            title = "Request Latency (p95)"
            metrics = [
            [
                "AWS/ApplicationELB",
                "TargetResponseTime",
                "LoadBalancer",
                var.alb_arn_suffix,
                { "stat": "p95" }
            ]
            ]
            period = 60
        }
      } : null,
################# DB Latency vs IntegrationLatency to determine slowness on APIGW itself or downstream services
      local.use_apigw ? {
        type = "metric"
        properties = {
            title = "API Gateway Latency (p95)"
            period = 60
            metrics = [
            [
                "AWS/ApiGateway",
                "Latency",
                "ApiId",
                var.apigw_api_id,
                "Stage",
                var.environment,
                { "stat": "p95" }
            ]
            ]
        }
      } : null,
      local.useapigw ? {
        type = "metric"
        properties = {
            title = "API Gateway Integration Latency (p95)"
            period = 60
            metrics = [
            [
                "AWS/ApiGateway",
                "IntegrationLatency",
                "ApiId",
                var.apigw_api_id,
                "Stage",
                var.environment,
                { "stat": "p95" }
            ]
            ]
        }
      },
################# DB Latency
      {
        type = "metric"
        properties = {
            title = "Aurora Read & Write Latency (ms)"
            period = 60
            metrics = [
            [
                "AWS/RDS",
                "ReadLatency",
                "DBClusterIdentifier",
                var.aurora_cluster_identifier,
                { "stat": "Average" }
            ],
            [
                ".",
                "WriteLatency",
                ".",
                ".",
                { "stat": "Average" }
            ]
            ]
        }
      },
################# Compute saturation  
      {
        type = "metric"
        properties = {
            title = "ECS CPU Utilization"
            metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
            ]
            stat   = "Average"
            period = 60
        }
      },
      {
        type = "metric"
        properties = {
            title = "ECS Memory Utilization"
            metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
            ]
            stat   = "Average"
            period = 60
        }
      },
################# DB Saturation  
      {
        type = "metric"
        properties = {
          title = "Aurora CPU"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", var.aurora_cluster_identifier]
          ]
          stat   = "Average"
          period = 60
        }
      }
    ])
  })
}
