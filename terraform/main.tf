


resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = module.vpc_eks.private_subnets
    security_group_ids      = []
    endpoint_private_access = "true"
    endpoint_public_access  = "true"
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  bootstrap_self_managed_addons = false

  zonal_shift_config {
    enabled = true
  }

  compute_config {
    enabled       = true
    node_pools    = var.eks_auto_node_pool
    node_role_arn = aws_iam_role.node.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }
}

