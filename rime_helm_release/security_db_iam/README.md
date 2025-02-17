<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.20.0, < 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.20.0, < 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_assumable_role_with_oidc_for_api_gateway_access"></a> [iam\_assumable\_role\_with\_oidc\_for\_api\_gateway\_access](#module\_iam\_assumable\_role\_with\_oidc\_for\_api\_gateway\_access) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.security_db_gateway_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_document.security_db_gateway_access_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The k8s namespace to install the RIME cluster into | `string` | n/a | yes |
| <a name="input_oidc_provider_url"></a> [oidc\_provider\_url](#input\_oidc\_provider\_url) | URL to the OIDC provider for IAM assumable roles used by K8s. | `string` | n/a | yes |
| <a name="input_resource_name_suffix"></a> [resource\_name\_suffix](#input\_resource\_name\_suffix) | A suffix to name the IAM policy and role with. | `string` | n/a | yes |
| <a name="input_service_account_names"></a> [service\_account\_names](#input\_service\_account\_names) | The names of the service accounts to link to the IAM role | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_security_db_gateway_role_arn"></a> [security\_db\_gateway\_role\_arn](#output\_security\_db\_gateway\_role\_arn) | n/a |
<!-- END_TF_DOCS -->
