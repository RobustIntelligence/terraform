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
| <a name="module_iam_assumable_role_with_oidc_for_s3_access"></a> [iam\_assumable\_role\_with\_oidc\_for\_s3\_access](#module\_iam\_assumable\_role\_with\_oidc\_for\_s3\_access) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.eks_s3_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_document.eks_s3_access_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The k8s namespace to install the rime-agent into | `string` | n/a | yes |
| <a name="input_oidc_provider_url"></a> [oidc\_provider\_url](#input\_oidc\_provider\_url) | URL to the OIDC provider for IAM assumable roles used by K8s. | `string` | n/a | yes |
| <a name="input_resource_name_suffix"></a> [resource\_name\_suffix](#input\_resource\_name\_suffix) | A suffix to name the IAM policy and role with. | `string` | n/a | yes |
| <a name="input_s3_authorized_bucket_path_arns"></a> [s3\_authorized\_bucket\_path\_arns](#input\_s3\_authorized\_bucket\_path\_arns) | A list of all S3 bucket path arns of which RIME will be granted access to.<br>  Each path must be of the form:<br>      arn:aws:s3:::<BUCKET>/sub/path<br>  where <BUCKET> is the name of the S3 bucket and `sub/path` comprises<br>  some path within the bucket. You can also use wildcards '?' or '*' within<br>  the arn specification (e.g. 'arn:aws:s3:::datasets/*'). | `list(string)` | n/a | yes |
| <a name="input_service_account_names"></a> [service\_account\_names](#input\_service\_account\_names) | The names of the service accounts to link to the IAM role | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_reader_role_arn"></a> [s3\_reader\_role\_arn](#output\_s3\_reader\_role\_arn) | n/a |
<!-- END_TF_DOCS -->
