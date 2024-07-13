output "bedrock_access_role_arn" {
  value = module.iam_assumable_role_with_oidc_for_bedrock_access.this_iam_role_arn
}
