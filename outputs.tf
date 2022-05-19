output "route53_admin_role_arn" {
  value = module.rime_kube_system_helm_release.route53_admin_role_arn
}

output "acm_cert_arn" {
  value = local.rime_domain != "" ? data.aws_acm_certificate.this_zone_acm_certificate[0].arn : ""
}
