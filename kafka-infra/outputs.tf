output "db_endpoint" { value = aws_db_instance.pg.address }
output "db_secret_arn" { value = aws_secretsmanager_secret.db.arn }
output "eso_irsa_role_arn" { value = aws_iam_role.eso.arn }
output "eks_node_role_arn" { value = aws_iam_role.eks_node.arn }
