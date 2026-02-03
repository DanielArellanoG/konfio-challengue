locals {
  services = {
    loan-api = {
      image = var.docker_images["loan_api"]
      port  = 8080
    }
    auth-service = {
      image = var.docker_images["auth_service"]
      port  = 8081
    }
    scoring-service = {
      image = var.docker_images["scoring_service"]
      port  = 8082
    }
  }
}

############################## ECS CLUSTER ##############################
resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-ecs-cluster"
}
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-task-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

############################## ECS TASK DEFINITIONS ##############################
resource "aws_ecs_task_definition" "this" {
  for_each = local.services

  family                   = "${local.name_prefix}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name  = each.key
    image = each.value.image
    portMappings = [{
      containerPort = each.value.port
    }]
    environment = [
      { name = "ENV", value = var.environment },
      { name = "DB_HOST", value = aws_rds_cluster.this.endpoint }
    ]
  }])
}

############################## ECS SERVICES ##############################
resource "aws_lb_target_group" "loan_api" {
  port     = 8080
  protocol = local.use_alb ? "HTTP" : "TCP"
  vpc_id   = aws_vpc.this.id
}

resource "aws_ecs_service" "this" {
  for_each = local.services

  name            = "${local.name_prefix}-${each.key}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = aws_subnet.public[*].id
    assign_public_ip = true
  }

  dynamic "load_balancer" {
    for_each = local.use_alb && each.key == "loan-api" ? [1] : [] # PENDING: add lbs to the other services.
    content {
      target_group_arn = aws_lb_target_group.loan_api.arn
      container_name   = each.key
      container_port   = 8080
    }
  }
}
