output "db_endpoint" { value = aws_db_instance.pg.address }
output "db_secret_arn" { value = aws_secretsmanager_secret.db.arn }
output "eso_irsa_role_arn" { value = aws_iam_role.eso.arn }
output "eks_node_role_arn" { value = aws_iam_role.eks_node.arn }
output "ecr_repository_urls" { value = { for k, r in aws_ecr_repository.repos : k => r.repository_url } }
output "ecr_registry_uri" { value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com" }
output "acm_dashboard_cert_arn" { value = aws_acm_certificate_validation.dashboard.certificate_arn }
output "imgupd_irsa_role_arn" { value = aws_iam_role.imgupd_irsa.arn }
