locals {
    vpc_cidr = "10.0.0.0/16"
    # azs = ["${var.region}a", "${var.region}b"]
    app_port = 8080
    db_port = 5432 # 3306 for MySQL
}
data "aws_availability_zones" "available" {}

########################### VPC & Gateways ###########################
resource "aws_vpc" "this" {
  cidr_block = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.environment}-vpc"
  }
}
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-igw"
  }
}
resource "aws_eip" "nat" {
  domain = "vpc" # ?????
}
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.environment}-nat"
  }
}

########################### SUBNETS & ROUTE TABLES ###########################
resource "aws_subnet" "public" {
  count = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 8, count.index)
  # availability_zone       = var.azs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment}-public-${count.index}"
  }
}
resource "aws_subnet" "private_app" {
  count = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index + 10)
  # availability_zone = var.azs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.environment}-private-app-${count.index}"
  }
}
resource "aws_subnet" "private_db" {
  count = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index + 20)
  # availability_zone = var.azs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.environment}-private-db-${count.index}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = {
    Name = "${var.environment}-private-rt"
  }
}
resource "aws_route_table_association" "private_app" {
  count          = 2
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_db" {
  count          = 2
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}

########################### Security groups ###########################
resource "aws_security_group" "alb" {
  count = local.use_alb ? 1 : 0
  name        = "${var.environment}-alb-sg"
  description = "ALB ingress"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.environment}-ecs-sg"
  description = "ECS service"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-ecs-sg"
  }
}
resource "aws_security_group_rule" "ecs_from_alb" {
  count = local.use_alb ? 1 : 0
  type                     = "ingress"
  from_port                = local.app_port
  to_port                  = local.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.alb[0].id
}
resource "aws_security_group_rule" "ecs_from_nlb" {
  count = local.use_apigw ? 1 : 0
  type              = "ingress"
  from_port         = local.app_port
  to_port           = local.app_port
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs.id
  cidr_blocks = aws_subnet.private_app[*].cidr_block
  # cidr_blocks = [
  #   aws_subnet.private_app[0].cidr_block,
  #   aws_subnet.private_app[1].cidr_block
  # ]
}

resource "aws_security_group" "aurora" {
  name        = "${var.environment}-aurora-sg"
  description = "Aurora access"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "From ECS only"
    from_port       = local.db_port
    to_port         = local.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
    # cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-aurora-sg"
  }
}

resource "aws_security_group" "vpc_link" {
  count = local.use_apigw ? 1 : 0
  name        = "${var.environment}-vpc-link-sg"
  description = "API Gateway VPC Link"
  vpc_id      = aws_vpc.this.id
  egress {
    description = "To NLB"
    from_port   = local.app_port
    to_port     = local.app_port
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private_app[*].cidr_block
    # cidr_blocks = [
    #   aws_subnet.private_app[0].cidr_block,
    #   aws_subnet.private_app[1].cidr_block
    # ]
  }

  # No ingress needed — API Gateway initiates connections
  tags = {
    Name = "${var.environment}-vpc-link-sg"
  }
}
