# Give the GH OIDC role cluster-admin on this cluster
resource "aws_eks_access_entry" "gha" {
  cluster_name  = var.eks_cluster_name
  principal_arn = var.github_actions_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "gha_admin" {
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_eks_access_entry.gha.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
}
