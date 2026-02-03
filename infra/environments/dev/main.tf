variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}
variable "environment" {
  description = "Select environment"
  type        = string
  default     = "dev"
}
variable "entrypoint_type" {
  description = "Select either ALB or API gateway"
  type        = string
  default     = "apigw"
}

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-bucket"
    key            = "${var.environment}/terraform.tfstate"
    region         = "${var.region}"
  }
}

provider "aws" {
  region = var.region
}

module "demo" {
  source = "../../modules/demo"

  environment     = var.environment
  region          = var.region
  entrypoint_type = var.entrypoint_type

  docker_images = {
    loan_api       = "danarellanog/loan-api:latest"
    auth_service   = "danarellanog/auth-service:latest"
    scoring_service= "danarellanog/scoring-service:latest"
  }
}

# module "o11y" {
#   source = "../../modules/o11y"

#   environment = var.environment

#   # Explicit wiring = good SRE signal
#   alb_arn          = module.demo.alb_arn
#   ecs_cluster_name = module.demo.ecs_cluster_name
#   services         = module.demo.ecs_services
#   endpoint         = module.demo.endpoint
# }


