resource "aws_acm_certificate" "rime_domain_cert" {
  domain_name       = var.domain
  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "rime_domain_cert_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.rime_domain_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.registered_domain_zone_id
}

resource "aws_acm_certificate_validation" "rime_domain_cert_validation" {
  certificate_arn         = aws_acm_certificate.rime_domain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.rime_domain_cert_validation_records : record.fqdn]
}
