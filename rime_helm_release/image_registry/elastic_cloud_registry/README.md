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

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_assumable_role_with_oidc_for_ecr_image_builder"></a> [iam\_assumable\_role\_with\_oidc\_for\_ecr\_image\_builder](#module\_iam\_assumable\_role\_with\_oidc\_for\_ecr\_image\_builder) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |
| <a name="module_iam_assumable_role_with_oidc_for_ecr_repo_management"></a> [iam\_assumable\_role\_with\_oidc\_for\_ecr\_repo\_management](#module\_iam\_assumable\_role\_with\_oidc\_for\_ecr\_repo\_management) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.eks_ecr_image_builder_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.eks_ecr_repo_management_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.eks_ecr_image_builder_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_ecr_repo_management_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where the RIME Helm chart is to be installed. | `string` | n/a | yes |
| <a name="input_oidc_provider_url"></a> [oidc\_provider\_url](#input\_oidc\_provider\_url) | URL to the OIDC provider for IAM assumable roles used by K8s. | `string` | n/a | yes |
| <a name="input_repository_prefix"></a> [repository\_prefix](#input\_repository\_prefix) | Prefix used for all repositories created and managed by the RIME Image Registry service. Will also be joined with namespace and resource suffix. | `string` | `"rime-managed-images"` | no |
| <a name="input_resource_name_suffix"></a> [resource\_name\_suffix](#input\_resource\_name\_suffix) | A suffix to name the IAM policy and role with. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecr_config"></a> [ecr\_config](#output\_ecr\_config) | n/a |
| <a name="output_managed-image-repo-admin-annotation"></a> [managed-image-repo-admin-annotation](#output\_managed-image-repo-admin-annotation) | n/a |
| <a name="output_managed-image-repo-builder-annotation"></a> [managed-image-repo-builder-annotation](#output\_managed-image-repo-builder-annotation) | n/a |
<!-- END_TF_DOCS -->
