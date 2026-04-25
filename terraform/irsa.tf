resource "aws_iam_policy" "secrets_policy" {
  name = "node-app-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.db_secret.arn
      }
    ]
  })
}

module "node_app_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "node-app-irsa-role"

  role_policy_arns = {
    secrets = aws_iam_policy.secrets_policy.arn
  }

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "dev:node-app-sa",
        "prod:node-app-sa"
      ]
    }
  }
}

output "node_app_irsa_role_arn" {
  value = module.node_app_irsa.iam_role_arn
}