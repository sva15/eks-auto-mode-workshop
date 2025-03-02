resource "aws_efs_file_system" "wordpress_efs" {
  creation_token = "${var.cluster_name}-wordpress-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"  # Enable Intelligent-Tiering
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "${var.cluster_name}-wordpress-efs"
  }
}

# Security Group for EFS
resource "aws_security_group" "efs_sg" {
  name        = "${var.cluster_name}-efs-security-group"
  description = "Allow EKS Nodes to Access EFS"
  vpc_id      = module.vpc_eks.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Allow EKS Nodes
  }

  tags = {
    Name = "${var.cluster_name}-efs-security-group"
  }
}

# Create Mount Targets in Private Subnets
resource "aws_efs_mount_target" "efs_mount" {
  count = length(module.vpc_eks.private_subnets)

  file_system_id  = aws_efs_file_system.wordpress_efs.id
  subnet_id       = module.vpc_eks.private_subnets[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}

# Create an EFS Access Point
resource "aws_efs_access_point" "wordpress_ap" {
  file_system_id = aws_efs_file_system.wordpress_efs.id

  root_directory {
    path = "/wordpress"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }

  posix_user {
    uid = 1000
    gid = 1000
  }

  tags = {
    Name = "${var.cluster_name}-wordpress-efs-ap"
  }
}


