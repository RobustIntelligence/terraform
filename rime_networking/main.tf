

data "aws_route53_zone" "root_zone" {
  name     = "rbst.io"
  provider = aws.root
}

### Cross-account DNS delegation
resource "aws_route53_zone" "sub_domain_zone" {
  count = var.cross_account ? 1 : 0
  name  = var.domain
}

resource "aws_route53_record" "root_zone_ns_record" {
  count   = var.cross_account ? 1 : 0
  zone_id = data.aws_route53_zone.root_zone.zone_id
  type    = "NS"
  name    = var.domain
  ttl     = 300
  records = [
    # The values are equivilant to the NS records of the subdomain zone
    aws_route53_zone.sub_domain_zone[0].name_servers[0],
    aws_route53_zone.sub_domain_zone[0].name_servers[1],
    aws_route53_zone.sub_domain_zone[0].name_servers[2],
    aws_route53_zone.sub_domain_zone[0].name_servers[3],
  ]
  provider = aws.root
}

### RIME ACM Certificate
resource "aws_acm_certificate" "rime_domain_cert" {
  count                     = var.rime_deployment ? 1 : 0
  domain_name               = "rime.${var.domain}"
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "rime_domain_cert_validation_records" {
  for_each = var.rime_deployment ? {
    for dvo in aws_acm_certificate.rime_domain_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.cross_account ? aws_route53_zone.sub_domain_zone[0].zone_id : data.aws_route53_zone.root_zone.zone_id
}

resource "aws_acm_certificate_validation" "rime_domain_cert_validation" {
  count                   = var.rime_deployment ? 1 : 0
  certificate_arn         = aws_acm_certificate.rime_domain_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.rime_domain_cert_validation_records : record.fqdn]
}

### FW ACM Certificate
resource "aws_acm_certificate" "fw_domain_cert" {
  count                     = var.fw_deployment ? 1 : 0
  domain_name               = "firewall.${var.domain}"
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "fw_domain_cert_validation_records" {
  for_each = var.fw_deployment ? {
    for dvo in aws_acm_certificate.fw_domain_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.cross_account ? aws_route53_zone.sub_domain_zone[0].zone_id : data.aws_route53_zone.root_zone.zone_id
}

resource "aws_acm_certificate_validation" "fw_domain_cert_validation" {
  count                   = var.fw_deployment ? 1 : 0
  certificate_arn         = aws_acm_certificate.fw_domain_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.fw_domain_cert_validation_records : record.fqdn]
}
