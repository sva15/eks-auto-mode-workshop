# Security Group for Aurora - Allows MySQL Access from EKS Nodes
resource "aws_security_group" "aurora_sg" {
  name        = "${var.cluster_name}-aurora-sg"
  description = "Security group for Aurora MySQL allowing access from EKS"
  vpc_id      = module.vpc_eks.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Only allow EKS VPC access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-aurora-sg"
  }
}

# Store Database Credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_secret" {
  name = "${var.cluster_name}-aurora-db-secret-demo"
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
  })
}

# Generate a random password for the database
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!@#%^&*()-_=+[]{}<>:?"
}

# Aurora MySQL Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "aurora_pg" {
  name        = "${var.cluster_name}-aurora-pg"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL Cluster Parameter Group"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_general_ci"
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "${var.cluster_name}-aurora-subnet-group"
  subnet_ids = module.vpc_eks.private_subnets # ✅ Uses EKS VPC subnets

  tags = {
    Name = "${var.cluster_name}-aurora-subnet-group"
  }
}

# Aurora MySQL Serverless Cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${var.cluster_name}-aurora-cluster"
  engine                 = "aurora-mysql"
  engine_mode            = "provisioned" # Use "serverless" for Serverless v1
  engine_version         = "8.0.mysql_aurora.3.05.2" # Aurora MySQL 8
  database_name          = "wordpressdb"
  master_username        = jsondecode(aws_secretsmanager_secret_version.db_secret_version.secret_string)["username"]
  master_password        = jsondecode(aws_secretsmanager_secret_version.db_secret_version.secret_string)["password"]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_pg.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
  storage_encrypted      = true
  deletion_protection    = false
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2.0
  }

  skip_final_snapshot = true

  tags = {
    Name = "${var.cluster_name}-aurora"
  }
}

# Aurora MySQL Instance (Serverless)
resource "aws_rds_cluster_instance" "aurora_instance" {
  count                = 2
  identifier          = "${var.cluster_name}-aurora-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class      = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
}

# IAM Role for EKS to Access Secret Manager
resource "aws_iam_role" "eks_secret_access" {
  name = "${var.cluster_name}-eks-secret-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "secret_access_policy" {
  name        = "${var.cluster_name}-secret-access"
  description = "Allows access to Aurora MySQL secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = aws_secretsmanager_secret.db_secret.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_secret_access_attach" {
  policy_arn = aws_iam_policy.secret_access_policy.arn
  role       = aws_iam_role.eks_secret_access.name
}
