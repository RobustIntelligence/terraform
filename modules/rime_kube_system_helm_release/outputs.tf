output "cluster_autoscaler_role_arn" {
  value = var.install_cluster_autoscaler ? module.iam_assumable_role_with_oidc_for_autoscaler[0].this_iam_role_arn : ""
}

output "route53_admin_role_arn" {
  value = var.install_external_dns ? module.iam_assumable_role_with_oidc_for_route53[0].this_iam_role_arn : ""
}
