<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.75.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.75.0 |
| <a name="provider_aws.root"></a> [aws.root](#provider\_aws.root) | >= 3.75.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.fw_domain_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate.rime_domain_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.fw_domain_cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_acm_certificate_validation.rime_domain_cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_route53_record.fw_domain_cert_validation_records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.rime_domain_cert_validation_records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.root_zone_ns_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.sub_domain_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.root_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cross_account"></a> [cross\_account](#input\_cross\_account) | Boolean to enable/disable cross account ACM certificate creation | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain to create a cert for. This can also be a wildcard cert. Must be a child of the registered domain. | `string` | n/a | yes |
| <a name="input_fw_deployment"></a> [fw\_deployment](#input\_fw\_deployment) | Boolean to enable/disable FW ACM certificate creation | `bool` | `false` | no |
| <a name="input_rime_deployment"></a> [rime\_deployment](#input\_rime\_deployment) | Boolean to enable/disable RIME ACM certificate creation | `bool` | `false` | no |
| <a name="input_subject_alternative_names"></a> [subject\_alternative\_names](#input\_subject\_alternative\_names) | (Optional) Set of domains that should be SANs in the issued certificate. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fw_acm_cert_arn"></a> [fw\_acm\_cert\_arn](#output\_fw\_acm\_cert\_arn) | n/a |
| <a name="output_rime_acm_cert_arn"></a> [rime\_acm\_cert\_arn](#output\_rime\_acm\_cert\_arn) | n/a |
<!-- END_TF_DOCS -->
