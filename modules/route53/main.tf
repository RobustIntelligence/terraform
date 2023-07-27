locals {
  all_domains        = concat(var.secondary_domains, [var.primary_domain])
  domain_to_zone_id  = { for zone in data.aws_route53_zone.aws_route53_zones : zone.name => zone.zone_id }
  wildcard_to_domain = merge({ for domain in local.all_domains : "*.${domain}" => domain }, { (var.primary_domain) = var.primary_domain })
}

resource "aws_route53_zone" "created_route53_zone" {
  for_each = toset(local.all_domains)

  name = each.key
  tags = var.tags
}

data "aws_route53_zone" "aws_route53_zones" {
  for_each = toset(local.all_domains)

  depends_on = [aws_route53_zone.created_route53_zone]
  name       = each.key
}


resource "aws_acm_certificate" "rime_domain_cert" {
  domain_name               = var.acm_domain
  subject_alternative_names = [for key in keys(local.wildcard_to_domain) : key if key != var.primary_domain]
  validation_method         = "DNS"

  tags = var.tags
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
  zone_id         = local.domain_to_zone_id[local.wildcard_to_domain[each.key]]
}

resource "aws_acm_certificate_validation" "rime_domain_cert_validation" {
  certificate_arn         = aws_acm_certificate.rime_domain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.rime_domain_cert_validation_records : record.fqdn]
}
