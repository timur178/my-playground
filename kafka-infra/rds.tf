resource "aws_db_subnet_group" "pg" {
  name       = "${var.team}-${var.environment}-pg-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "pg" {
  name        = "${var.team}-${var.environment}-pg-sg"
  description = "PostgreSQL access from EKS nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "5432 from EKS nodes SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_nodes_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.team}/${var.environment}/postgres"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    dbname   = "${var.db_name}-${var.team}-${var.environment}"
  })
}

resource "aws_db_instance" "pg" {
  engine                      = "postgres"
  engine_version              = "17.4"
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  max_allocated_storage       = 100
  storage_encrypted           = true
  publicly_accessible         = false
  backup_retention_period     = 7
  db_subnet_group_name        = aws_db_subnet_group.pg.name
  vpc_security_group_ids      = [aws_security_group.pg.id]
  username                    = var.db_username
  password                    = random_password.db.result
  db_name                     = "${var.db_name}-${var.team}-${var.environment}"
  identifier                  = "pg-${var.team}-${var.environment}"
  skip_final_snapshot         = true
  allow_major_version_upgrade = true
  apply_immediately           = true
}
