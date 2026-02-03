variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "entrypoint_type" {
  type        = string
  description = "Entry point type: alb or apigw"
  validation {
    condition     = contains(["alb", "apigw"], var.entrypoint_type)
    error_message = "entrypoint_type must be alb or apigw"
  }
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "alb_arn_suffix" {
  type        = string
  description = "ALB ARN suffix (only if entrypoint_type = alb)"
  default     = null
}

variable "apigw_api_id" {
  type        = string
  description = "API Gateway ID (only if entrypoint_type = apigw)"
  default     = null
}

variable "aurora_cluster_identifier" {
  type = string
}

variable "alarm_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for alarm notifications"
  default     = null
}

variable "thresholds" {
  description = "Alarm thresholds"
  type = object({
    ecs_cpu_high            = number
    ecs_memory_high         = number
    alb_5xx_rate            = number
    apigw_5xx_rate          = number
    latency_p95_ms          = number
    aurora_cpu_high         = number
    aurora_connections_high = number
  })
}
