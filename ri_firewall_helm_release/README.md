<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.14, < 2.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | > 2.1.0, < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | > 2.1.0, < 3.0.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0.1, < 3.0.0 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_blob_store"></a> [blob\_store](#module\_blob\_store) | ../rime_helm_release/blob_store | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.ri_firewall](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.docker-secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.integration_secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [local_file.helm_values](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_cert_arn"></a> [acm\_cert\_arn](#input\_acm\_cert\_arn) | ARN for the ACM cert to validate our domain. | `string` | n/a | yes |
| <a name="input_base_firewall_config"></a> [base\_firewall\_config](#input\_base\_firewall\_config) | Initial firewall system configuration.<br>  This includes information about which model provider (OpenAI or Azure OpenAI)<br>  we will use for evaluation.<br>  It has no customer configuration; the customer can configure certain fields<br>  later with an API call. | `map(any)` | n/a | yes |
| <a name="input_create_managed_helm_release"></a> [create\_managed\_helm\_release](#input\_create\_managed\_helm\_release) | Whether to deploy a RI Firewall Helm chart onto the provisioned infrastructure managed by Terraform.<br>  Changing the state of this variable will either install/uninstall the RI Firewall deployment<br>  once the change is applied in Terraform. If you want to install the RI Firewall package manually,<br>  set this to false and use the generated values YAML file to deploy the release<br>  on the provisioned infrastructure. | `bool` | `false` | no |
| <a name="input_datadog_tag_pod_annotation"></a> [datadog\_tag\_pod\_annotation](#input\_datadog\_tag\_pod\_annotation) | Pod annotation for Datadog tagging. Must be a string in valid JSON format, e.g. {"tag": "val"}. | `string` | `""` | no |
| <a name="input_docker_credentials"></a> [docker\_credentials](#input\_docker\_credentials) | Credentials to pass into docker image pull secrets. Has creds for all registries. Must be structured like so:<br>  [{<br>    docker-server= "",<br>    docker-username="",<br>    docker-password="",<br>    docker-email=""<br>  }] | `list(map(string))` | n/a | yes |
| <a name="input_docker_secret_name"></a> [docker\_secret\_name](#input\_docker\_secret\_name) | The name of the Kubernetes secret used to pull the Docker image for RIME's backend services. | `string` | `"rimecreds"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain to use for the Firewall. | `string` | n/a | yes |
| <a name="input_file_storage_server_service_account_name"></a> [file\_storage\_server\_service\_account\_name](#input\_file\_storage\_server\_service\_account\_name) | Custom service account name for firewall's storage server. | `string` | `"ri-firewall-file-storage-server"` | no |
| <a name="input_firewall_server_service_account_name"></a> [firewall\_server\_service\_account\_name](#input\_firewall\_server\_service\_account\_name) | Custom service account name for the firewall server. | `string` | `"ri-firewall-firewall-server"` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Whether or not to force destroy the blob store bucket | `bool` | `false` | no |
| <a name="input_manage_namespace"></a> [manage\_namespace](#input\_manage\_namespace) | Whether or not to manage the namespace we are installing into.<br>  This will create the namespace(if applicable), setup docker credentials as a<br>  kubernetes secret etc. Turn this flag off if you have trouble connecting to<br>  k8s from your terraform environment. | `bool` | `true` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where the RI Firewall Helm chart will be installed. | `string` | n/a | yes |
| <a name="input_oidc_provider_url"></a> [oidc\_provider\_url](#input\_oidc\_provider\_url) | URL to the OIDC provider for IAM assumable roles used by K8s. | `string` | n/a | yes |
| <a name="input_openai_api_key"></a> [openai\_api\_key](#input\_openai\_api\_key) | Open AI API key for using tests that rely on OpenAI models. | `string` | n/a | yes |
| <a name="input_override_values_file_path"></a> [override\_values\_file\_path](#input\_override\_values\_file\_path) | Optional file path to override values file for the ri firewall helm release.<br>  These values take precendence over values produced by the terraform module. | `string` | `""` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | helm release name | `string` | `"ri-firewall"` | no |
| <a name="input_resource_name_suffix"></a> [resource\_name\_suffix](#input\_resource\_name\_suffix) | A suffix to name the IAM policy and role with. | `string` | n/a | yes |
| <a name="input_ri_firewall_repository"></a> [ri\_firewall\_repository](#input\_ri\_firewall\_repository) | Repository URL where to locate the requested RI Firewall chart for the given `ri_firewall_version`. | `string` | n/a | yes |
| <a name="input_ri_firewall_version"></a> [ri\_firewall\_version](#input\_ri\_firewall\_version) | The version of the RI Firewall software to be installed. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only. | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->