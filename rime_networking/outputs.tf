output "rime_acm_cert_arn" {
  value = var.rime_deployment ? aws_acm_certificate.rime_domain_cert[0].arn : null
}

output "fw_acm_cert_arn" {
  value = var.fw_deployment ? aws_acm_certificate.fw_domain_cert[0].arn : null
}
