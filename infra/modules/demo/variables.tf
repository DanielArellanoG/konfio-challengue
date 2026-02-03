variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "entrypoint_type" {
  type    = string
  validation {
    condition     = contains(["alb", "apigw"], var.entrypoint_type)
    error_message = "entrypoint_type must be 'alb' or 'apigw'"
  }
}

variable "docker_images" {
  type = map(string)
}
