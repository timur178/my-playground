data "aws_iam_policy_document" "imgupd_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.eks_oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.eks_oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:argocd:argocd-image-updater"]
    }
  }
}

resource "aws_iam_role" "imgupd_irsa" {
  name               = "argocd-image-updater-${var.team}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.imgupd_trust.json
}

# ECR read-only is enough (includes GetAuthorizationToken)
resource "aws_iam_role_policy_attachment" "imgupd_ecr_ro" {
  role       = aws_iam_role.imgupd_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
