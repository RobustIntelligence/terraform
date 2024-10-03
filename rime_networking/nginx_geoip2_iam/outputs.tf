output "nginx_geoip2_role_arn" {
  value = module.iam_assumable_role_with_oidc_geoip2.this_iam_role_arn
}
