output "security_db_gateway_role_arn" {
  value = module.iam_assumable_role_with_oidc_for_api_gateway_access.this_iam_role_arn
}
