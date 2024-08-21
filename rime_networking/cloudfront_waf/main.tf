locals {
  customer_name = strcontains(var.namespace, "firewall") ? "ri-firewall-${lower(var.customer_name)}" : "rime-${lower(var.customer_name)}"
}

data "kubernetes_service" "ingress_nginx_svc" {
  metadata {
    name      = "${local.customer_name}-ingress-nginx-controller"
    namespace = var.namespace
  }
}

resource "aws_s3_bucket" "cf_logs_bucket" {
  bucket = "${lower(var.namespace)}-cf-logs-bucket"
  lifecycle { # Terraform bug that sees drift because Cloudfront is modifying the bucket permissions
    ignore_changes = [
      grant
    ]
  }
  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "cf_logs_bucket_ownership_controls" {
  bucket = aws_s3_bucket.cf_logs_bucket.bucket

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log-delivery-acl" {
  bucket = aws_s3_bucket.cf_logs_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_cloudfront_distribution" "cf_distribution" {
  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    domain_name = data.kubernetes_service.ingress_nginx_svc.status[0].load_balancer[0].ingress[0].hostname
    origin_id   = local.customer_name
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for ${local.customer_name}"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cf_logs_bucket.bucket_domain_name
  }

  aliases = [var.hostname_alias]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.customer_name

    cache_policy_id          = "83da9c7e-98b4-4e11-a168-04f0df8e2c65" # UseOriginCacheControlHeaders
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer

    viewer_protocol_policy = "https-only"
  }

  price_class = "PriceClass_200" # Every edge cache except South America and Australia

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["IR", "CU", "SY", "KP", "UA"] # ISO 3166 country codes
    }
  }

  tags = merge(var.tags, { "helm_release" = var.dependency_link })

  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021" # Recommended by AWS
  }
}

# Add the CloudFront distribution hostname as an annotation so external-dns can create a an Alias record in Route 53
# Managed outside of the helm charts because Cloudfront depends on the Load Balancers existing first
resource "kubernetes_annotations" "external_dns_annotations" {
  api_version = "networking.k8s.io/v1"
  kind        = "Ingress"
  metadata {
    name      = "${local.customer_name}-ingress"
    namespace = var.namespace
  }
  annotations = {
    "external-dns.alpha.kubernetes.io/target" = aws_cloudfront_distribution.cf_distribution.domain_name
    "external-dns.alpha.kubernetes.io/alias"  = "true"
  }
}

resource "kubernetes_annotations" "external_dns_annotations_auth_ingress" {
  api_version = "networking.k8s.io/v1"
  kind        = "Ingress"
  metadata {
    name      = "${local.customer_name}-auth-ingress"
    namespace = var.namespace
  }
  annotations = {
    "external-dns.alpha.kubernetes.io/target" = aws_cloudfront_distribution.cf_distribution.domain_name
    "external-dns.alpha.kubernetes.io/alias"  = "true"
  }
}
