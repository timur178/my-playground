# who am I? used to build the registry URI output
data "aws_caller_identity" "current" {}

# optional: prefix repos by team/env to avoid name collisions across envs
locals {
  repo_names = toset(var.ecr_repo_names)
  repo_map = { for n in local.repo_names :
    n => (var.ecr_repo_prefix != "" ? "${var.ecr_repo_prefix}/${n}" : n)
  }
}

# ----- Private ECR repositories (one per app) -----
resource "aws_ecr_repository" "repos" {
  for_each             = local.repo_map
  name                 = each.value
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
}

# Lifecycle: keep last N, expire untagged quickly (prevents repo bloat)
resource "aws_ecr_lifecycle_policy" "lc" {
  for_each   = aws_ecr_repository.repos
  repository = each.value.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 2 days"
        action       = { type = "expire" }
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countNumber = 2,
          countUnit   = "days"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 tagged images"
        action       = { type = "expire" }
        selection = {
          tagStatus      = "tagged",
          countType      = "imageCountMoreThan",
          countNumber    = 5,
          tagPatternList = ["*"]
        }
      }
    ]
  })
}
