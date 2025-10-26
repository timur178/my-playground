data "aws_iam_openid_connect_provider" "existing" {
  count = var.create ? 0 : 1
  url   = var.url
}

data "tls_certificate" "github_oidc" {
  url = var.url
}

locals {
  github_oidc_arn = try(
    aws_iam_openid_connect_provider.github[0].arn,
    data.aws_iam_openid_connect_provider.existing[0].arn
  )

  github_oidc_thumbprint = data.tls_certificate.github_oidc.certificates[
    length(data.tls_certificate.github_oidc.certificates) - 1
  ].sha1_fingerprint
}

resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create ? 1 : 0
  url            = var.url
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "2b18947a6a9fc7764fd8b5fb18a863b0c6dac24f",
    "${local.github_oidc_thumbprint}"
  ]
}

data "aws_iam_policy_document" "gha_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "gha_oidc_role" {
  name               = "${var.oidc_role_name}-${var.project}"
  description        = "Deploy role assumed by GitHub Actions (${var.github_org}/${var.github_repo})"
  assume_role_policy = data.aws_iam_policy_document.gha_assume_role.json
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.gha_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "AWS_OIDC_ROLE_ARN" {
  value = aws_iam_role.gha_oidc_role.arn
}
