<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.75.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecr"></a> [ecr](#module\_ecr) | ./elastic_cloud_registry | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_platform_config"></a> [cloud\_platform\_config](#input\_cloud\_platform\_config) | A configuration that is specific to the cloud platform being used | <pre>object({<br>    platform_type = string<br>    // TODO(11974): make this optional once we switch to TF >= 1.3.0.<br>    aws_config = object({})<br>    // TODO(11974): make this optional once we switch to TF >= 1.3.0.<br>    gcp_config = object({<br>      location      = string<br>      project       = string<br>      node_sa_email = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_image_registry_config"></a> [image\_registry\_config](#input\_image\_registry\_config) | The configuration for the RIME Image Registry service, which manages custom images<br>  for running RIME stress tests with different Python model requirements:<br>    * enable:                       whether or not to enable the RIME Image Registry service.<br>    * repo\_base\_name:               the base name used for all repositories created<br>                                    and managed by the RIME Image Registry service. | <pre>object({<br>    enable         = bool<br>    repo_base_name = string<br>  })</pre> | <pre>{<br>  "enable": true,<br>  "repo_base_name": "rime-managed-images"<br>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where the RIME Helm chart is to be installed. | `string` | n/a | yes |
| <a name="input_oidc_provider_url"></a> [oidc\_provider\_url](#input\_oidc\_provider\_url) | URL to the OIDC provider for IAM assumable roles used by K8s. | `string` | n/a | yes |
| <a name="input_resource_name_suffix"></a> [resource\_name\_suffix](#input\_resource\_name\_suffix) | A suffix to name the IAM policy and role with. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_image_registry_config"></a> [image\_registry\_config](#output\_image\_registry\_config) | n/a |
<!-- END_TF_DOCS -->
