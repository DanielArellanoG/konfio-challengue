resource "aws_db_subnet_group" "this" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id
  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = local.name_prefix
  engine             = "aurora-postgresql"
  master_username    = "demo"
  master_password    = "demopassword123"
  database_name      = "loan_db"
  skip_final_snapshot = true
}

resource "aws_rds_cluster_instance" "this" {
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.this.engine
}
