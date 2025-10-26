resource "aws_eks_node_group" "kafka_ng" {
  cluster_name    = var.eks_cluster_name
  node_group_name = "kafka-node-group-${var.team}-${var.environment}"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["c5.large"]

  labels = {
    "dedicated" = "kafka"
  }

  taint {
    key    = "dedicated"
    value  = "kafka"
    effect = "NO_SCHEDULE"
  }

  update_config { max_unavailable = 1 }

  tags = {
    "Name"        = "kafka-node-group-${var.team}-${var.environment}"
    "Team"        = var.team
    "Environment" = var.environment
  }
}
