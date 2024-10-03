resource "aws_iam_policy" "eks_geoip2_policy" {
  name = "eks_geoip2_${var.resource_name_suffix}_policy"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action : [
          "s3:ListBucket",
          "s3:GetObject",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::geoip2-s3-storage-bucket",
          "arn:aws:s3:::geoip2-s3-storage-bucket/*"
        ]
      },
    ]
  })

  tags = var.tags
}

module "iam_assumable_role_with_oidc_geoip2" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 3.0"

  create_role = true

  role_name = "eks_geoip2_${var.resource_name_suffix}"

  provider_url = var.oidc_provider_url

  role_policy_arns = [
    aws_iam_policy.eks_geoip2_policy.arn,
  ]

  number_of_role_policy_arns = 1

  oidc_fully_qualified_subjects = [
    for service_account_name in var.service_account_names : "system:serviceaccount:${var.namespace}:${service_account_name}"
  ]

  tags = var.tags
}
